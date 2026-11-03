import {
  Card,
  CardBody,
  CardHeader,
  Code,
  Divider,
  Grid,
  H1,
  H2,
  H3,
  Pill,
  Row,
  Stack,
  Table,
  Text,
  computeDAGLayout,
  useHostTheme,
  useMemo,
  useState,
} from "cursor/canvas";

// Cursor canvas: only renders from Cursor's canvases directory (see
// "Application flow" in README.md). Keep it in sync with
// lib/services/navigation_service.dart and functions/index.js.

type NodeKind = "entry" | "screen" | "auth" | "data";

type FlowNode = {
  id: string;
  label: string;
  kind: NodeKind;
  summary: string;
  files: string[];
  services: string[];
};

const NODES: FlowNode[] = [
  {
    id: "launch",
    label: "App launch",
    kind: "entry",
    summary:
      "main.dart initializes Firebase and notifications. A cold start from a call notification opens /call directly; otherwise the app opens /welcome.",
    files: ["lib/main.dart", "lib/services/navigation_service.dart"],
    services: ["firebase_core", "App Check", "awesome_notifications"],
  },
  {
    id: "welcome",
    label: "Welcome",
    kind: "screen",
    summary: "Landing screen with LOGIN and REGISTER.",
    files: ["lib/screens/welcome_screen.dart"],
    services: [],
  },
  {
    id: "login",
    label: "Login",
    kind: "screen",
    summary:
      "Email + password form, Forgot password, and social buttons for Google and Apple. Facebook and Twitter code exists in AnyChatAuth, but their buttons are commented out.",
    files: ["lib/screens/login_screen.dart", "lib/screens/forgot_password.dart"],
    services: ["Firebase Auth"],
  },
  {
    id: "register",
    label: "Register",
    kind: "screen",
    summary:
      "Same providers as Login, gated on the terms-of-service checkbox (RegisterScreen.isUserAgreeToTerms).",
    files: ["lib/screens/register_screen.dart"],
    services: ["Firebase Auth"],
  },
  {
    id: "email",
    label: "Email / password",
    kind: "auth",
    summary:
      "createUserWithEmailAndPassword on register, signInWithEmailAndPassword on login. Weak passwords and emails already in use get localized toasts.",
    files: ["lib/database/anychat_auth.dart · signInEmail"],
    services: ["Firebase Auth: email provider"],
  },
  {
    id: "google",
    label: "Google",
    kind: "auth",
    summary:
      "google_sign_in on mobile (each Android signing key needs its SHA-1 registered in Firebase), signInWithPopup on web. Also requests the contacts.readonly scope.",
    files: ["lib/database/anychat_auth.dart · signInGoogle"],
    services: ["Firebase Auth: google.com", "OAuth clients in google-services.json"],
  },
  {
    id: "apple",
    label: "Apple",
    kind: "auth",
    summary: "sign_in_with_apple, exchanged for a Firebase OAuthProvider('apple.com') credential.",
    files: ["lib/database/anychat_auth.dart · signInApple"],
    services: ["Firebase Auth: apple.com"],
  },
  {
    id: "profile",
    label: "users/{uid} profile",
    kind: "data",
    summary:
      "Every sign-in method reads users/{uid}. On first sign-in it builds an AnyChatUser (display name, email, photo, device language, theme) and writes it with addUserToFirestore.",
    files: ["lib/database/anychat_auth.dart", "lib/database/anychat_user.dart · addUserToFirestore"],
    services: ["Cloud Firestore"],
  },
  {
    id: "conversations",
    label: "Conversations",
    kind: "screen",
    summary:
      "Home hub. Lists the user's conversations newest first, and links to people search, the live translator and settings.",
    files: ["lib/screens/conversations_screen.dart", "lib/widgets/anychat_drawer.dart"],
    services: ["Firestore: users/{uid}/conversations", "conversations"],
  },
  {
    id: "search",
    label: "Search people",
    kind: "screen",
    summary: "Searches the users collection and creates a two-person conversation.",
    files: ["lib/screens/search_screen.dart", "AnyChatUser.createConversation"],
    services: ["Firestore: users (read)", "conversations (create)"],
  },
  {
    id: "live",
    label: "Live translator",
    kind: "screen",
    summary:
      "Face-to-face mode, entirely on the device: microphone to Google Speech-to-Text, then Google Translate, shown on screen. Nothing is written to Firestore.",
    files: ["lib/screens/live_translator_screen.dart", "lib/components/audio_transcriber.dart"],
    services: ["Callable: getSpeechAccessToken", "Speech-to-Text", "Cloud Translation v2"],
  },
  {
    id: "settings",
    label: "Settings",
    kind: "screen",
    summary: "Theme, notifications, profile photo, blocked users and account options.",
    files: ["lib/screens/settings_screen.dart", "lib/screens/blocked_users_screen.dart"],
    services: ["Firestore: users/{uid}", "Cloud Storage: images/"],
  },
  {
    id: "languages",
    label: "Languages",
    kind: "screen",
    summary:
      "Picks the incoming and outgoing language for a conversation. Stored per user, so each reader sees their own translation.",
    files: ["lib/screens/languages_screen.dart", "lib/database/conversation_info.dart"],
    services: ["Firestore: users/{uid}/conversations/{cid}"],
  },
  {
    id: "chat",
    label: "Chat",
    kind: "screen",
    summary:
      "Streams conversations/{cid}/messages and renders each one as Typed + Translation. Translation runs on the reader's device and is never stored.",
    files: ["lib/screens/chat_screen.dart", "lib/widgets/message_widget.dart"],
    services: ["Firestore: messages", "Cloud Translation v2"],
  },
  {
    id: "call",
    label: "Video call",
    kind: "screen",
    summary:
      "Agora RTC call on channel = conversation id, with live captions read from transcribedMessages and translated into each viewer's profile language.",
    files: ["lib/screens/call_screen.dart", "lib/services/http_service.dart"],
    services: ["agora-auth endpoint", "Agora RTC", "Firestore: transcribedMessages"],
  },
];

const EDGES: Array<{ from: string; to: string }> = [
  { from: "launch", to: "welcome" },
  { from: "welcome", to: "login" },
  { from: "welcome", to: "register" },
  ...["email", "google", "apple"].flatMap((p) => [
    { from: "login", to: p },
    { from: "register", to: p },
    { from: p, to: "profile" },
  ]),
  { from: "profile", to: "conversations" },
  { from: "conversations", to: "search" },
  { from: "conversations", to: "live" },
  { from: "conversations", to: "settings" },
  { from: "search", to: "chat" },
  { from: "settings", to: "languages" },
  { from: "chat", to: "call" },
];

const NODE_W = 148;
const NODE_H = 46;

const KIND_LABEL: Record<NodeKind, string> = {
  entry: "entry",
  screen: "screen",
  auth: "sign-in",
  data: "Firestore",
};

function FlowDiagram({
  selected,
  onSelect,
}: {
  selected: string;
  onSelect: (id: string) => void;
}) {
  const theme = useHostTheme();
  const layout = useMemo(
    () =>
      computeDAGLayout({
        nodes: NODES.map((n) => ({ id: n.id })),
        edges: EDGES,
        direction: "vertical",
        nodeWidth: NODE_W,
        nodeHeight: NODE_H,
        rankGap: 40,
        nodeGap: 16,
        padding: 12,
      }),
    [],
  );
  const byId = useMemo(() => new Map(NODES.map((n) => [n.id, n])), []);
  const touchesSelected = (e: { from: string; to: string }) =>
    e.from === selected || e.to === selected;

  return (
    <div style={{ overflowX: "auto" }}>
      <svg
        width={layout.width}
        height={layout.height}
        style={{ display: "block", margin: "0 auto" }}
      >
        <defs>
          <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto">
            <path d="M0,0 L10,5 L0,10 z" fill={theme.stroke.primary} />
          </marker>
          <marker id="arrowAccent" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto">
            <path d="M0,0 L10,5 L0,10 z" fill={theme.accent.primary} />
          </marker>
        </defs>
        {layout.edges.map((e) => {
          const hot = touchesSelected(e);
          const midY = (e.sourceY + e.targetY) / 2;
          return (
            <path
              key={`${e.from}-${e.to}`}
              d={`M${e.sourceX},${e.sourceY} C${e.sourceX},${midY} ${e.targetX},${midY} ${e.targetX},${e.targetY}`}
              fill="none"
              stroke={hot ? theme.accent.primary : theme.stroke.secondary}
              strokeWidth={hot ? 1.6 : 1}
              markerEnd={hot ? "url(#arrowAccent)" : "url(#arrow)"}
            />
          );
        })}
        {layout.nodes.map((pos) => {
          const node = byId.get(pos.id)!;
          const isSel = node.id === selected;
          return (
            <g
              key={node.id}
              transform={`translate(${pos.x},${pos.y})`}
              onClick={() => onSelect(node.id)}
              style={{ cursor: "pointer" }}
            >
              <rect
                width={NODE_W}
                height={NODE_H}
                rx={6}
                fill={isSel ? theme.fill.secondary : theme.bg.elevated}
                stroke={isSel ? theme.accent.primary : theme.stroke.secondary}
                strokeWidth={isSel ? 1.6 : 1}
              />
              <text x={10} y={19} fontSize={12} fontWeight={600} fill={theme.text.primary}>
                {node.label}
              </text>
              <text x={10} y={35} fontSize={10.5} fill={theme.text.tertiary}>
                {KIND_LABEL[node.kind]}
              </text>
            </g>
          );
        })}
      </svg>
    </div>
  );
}

function NodeDetail({ node }: { node: FlowNode }) {
  const outgoing = EDGES.filter((e) => e.from === node.id).map((e) => e.to);
  const incoming = EDGES.filter((e) => e.to === node.id).map((e) => e.from);
  const label = (id: string) => NODES.find((n) => n.id === id)?.label ?? id;
  return (
    <Card>
      <CardHeader trailing={<Pill size="sm">{KIND_LABEL[node.kind]}</Pill>}>{node.label}</CardHeader>
      <CardBody>
        <Stack gap={12}>
          <Text>{node.summary}</Text>
          <Stack gap={4}>
            <Text size="small" tone="tertiary" weight="medium">Code</Text>
            {node.files.map((f) => (
              <Code key={f}>{f}</Code>
            ))}
          </Stack>
          {node.services.length > 0 ? (
            <Stack gap={4}>
              <Text size="small" tone="tertiary" weight="medium">Firebase and services</Text>
              <Row gap={6} wrap>
                {node.services.map((s) => (
                  <Pill key={s} size="sm">{s}</Pill>
                ))}
              </Row>
            </Stack>
          ) : null}
          <Divider />
          <Grid columns={2} gap={8}>
            {incoming.length > 0 ? (
              <Stack gap={2}>
                <Text size="small" tone="tertiary">Comes from</Text>
                <Text size="small">{incoming.map(label).join(", ")}</Text>
              </Stack>
            ) : null}
            {outgoing.length > 0 ? (
              <Stack gap={2}>
                <Text size="small" tone="tertiary">Leads to</Text>
                <Text size="small">{outgoing.map(label).join(", ")}</Text>
              </Stack>
            ) : null}
          </Grid>
        </Stack>
      </CardBody>
    </Card>
  );
}

type Step = { actor: string; action: string };

const LANES: Array<{ title: string; note: string; steps: Step[] }> = [
  {
    title: "Text chat",
    note: "Only the original text is stored. Each reader's device translates into that reader's language.",
    steps: [
      { actor: "Sender · Chat", action: "addMessageToConversation writes senderId, text and a server timestamp in a transaction" },
      { actor: "Firestore", action: "The same transaction bumps conversations/{cid}.timestamp so lists re-sort" },
      { actor: "Reader · Chat", action: "A snapshots() stream delivers the new message" },
      { actor: "Reader · client", action: "Picks incomingLanguage from users/{uid}/conversations/{cid}" },
      { actor: "Cloud Translation v2", action: "Batch translate (128 strings per call), render Typed + Translation" },
    ],
  },
  {
    title: "Video call captions",
    note: "Audio goes over Agora; captions travel through Firestore and are translated into each viewer's profile language.",
    steps: [
      { actor: "Chat → Call", action: "agora-auth returns an RTC token for channel = conversation id" },
      { actor: "Agora RTC", action: "Joins the audio and video channel" },
      { actor: "Speaker · client", action: "Streams mic audio to Speech-to-Text with a token from getSpeechAccessToken" },
      { actor: "Firestore", action: "addTranscribedMessage writes each line; the transcript is cleared when a call starts and ends" },
      { actor: "Viewer · client", action: "Translates into users/{uid}.language and shows a caption" },
    ],
  },
  {
    title: "Live translator",
    note: "Face-to-face conversations; nothing leaves the device except the speech and translation API calls.",
    steps: [
      { actor: "User", action: "Picks a target language and starts listening" },
      { actor: "getSpeechAccessToken", action: "Callable function returns a short-lived Speech-to-Text token" },
      { actor: "Speech-to-Text", action: "Streams recognized text back to AudioTranscriber" },
      { actor: "Cloud Translation v2", action: "getGoogleTranslation translates each recognized phrase" },
      { actor: "Screen", action: "Shows the translation as it arrives" },
    ],
  },
];

function Lane({ title, note, steps }: { title: string; note: string; steps: Step[] }) {
  const theme = useHostTheme();
  return (
    <Stack gap={8}>
      <Row gap={8} align="center">
        <H3>{title}</H3>
        <Text size="small" tone="tertiary">{note}</Text>
      </Row>
      <div style={{ display: "grid", gridTemplateColumns: `repeat(${steps.length}, minmax(0, 1fr))`, gap: 0 }}>
        {steps.map((s, i) => (
          <div
            key={s.actor + i}
            style={{
              padding: "10px 12px",
              borderTop: `2px solid ${theme.stroke.secondary}`,
              borderLeft: i === 0 ? "none" : `1px solid ${theme.stroke.tertiary}`,
            }}
          >
            <Stack gap={4}>
              <Row gap={6} align="center">
                <Text size="small" tone="quaternary">{i + 1}</Text>
                <Text size="small" weight="semibold">{s.actor}</Text>
              </Row>
              <Text size="small" tone="secondary">{s.action}</Text>
            </Stack>
          </div>
        ))}
      </div>
    </Stack>
  );
}

export default function AnyChatAppFlow() {
  const [selected, setSelected] = useState("chat");
  const node = NODES.find((n) => n.id === selected) ?? NODES[0];

  return (
    <Stack gap={24} style={{ padding: 24, maxWidth: 1280, margin: "0 auto" }}>
      <Stack gap={6}>
        <H1>AnyChat Translator: application flow</H1>
        <Text tone="secondary">
          How the Flutter client moves a user from launch to translated conversations, and which Firebase and Google
          services each step uses. Mapped from <Code>main</Code> of <Code>AdamTV/anychat</Code>.
        </Text>
        <Row gap={6} wrap>
          <Pill size="sm">Flutter 3.19 · Android, iOS, web</Pill>
          <Pill size="sm">Cloud Firestore</Pill>
          <Pill size="sm">Sign-in: email, Google, Apple</Pill>
          <Pill size="sm">Translation: Google Cloud Translation v2</Pill>
        </Row>
      </Stack>

      <Stack gap={10}>
        <Row justify="space-between" align="center">
          <H2>User journey</H2>
          <Text size="small" tone="tertiary">Click any box for details.</Text>
        </Row>
        <Grid columns="minmax(0, 1.7fr) minmax(300px, 1fr)" gap={20} align="start">
          <FlowDiagram selected={selected} onSelect={setSelected} />
          <div style={{ position: "sticky", top: 16 }}>
            <NodeDetail node={node} />
          </div>
        </Grid>
        <Text size="small" tone="quaternary">
          Source: routes in lib/services/navigation_service.dart and pushNamed calls across lib/.
        </Text>
      </Stack>

      <Divider />

      <Stack gap={18}>
        <H2>How speech and text get translated</H2>
        {LANES.map((lane) => (
          <Lane key={lane.title} {...lane} />
        ))}
      </Stack>

      <Divider />

      <Grid columns="minmax(0, 1fr) minmax(0, 1fr)" gap={24} align="start">
        <Stack gap={10}>
          <H2>Backend services</H2>
          <Table
            headers={["Service", "Defined in", "Used by"]}
            rows={[
              [<Code>getSpeechAccessToken</Code>, "functions/index.js (callable)", "Live translator, call captions"],
              [<Code>health</Code>, "functions/index.js (HTTPS)", "Emulator smoke test"],
              [<Code>agora-auth</Code>, "Deployed separately, not in this repo", "Video call token (http_service.dart)"],
              ["Cloud Translation v2", "Google Cloud API", "Chat, calls, live translator"],
              ["Speech-to-Text", "Google Cloud API (google_speech)", "Calls, live translator"],
              ["Agora RTC", "agora_rtc_engine", "Video calls"],
              ["Cloud Storage", "storage.rules", "Profile photos (images/)"],
            ]}
            framed
          />
          <Text size="small" tone="quaternary">Source: functions/index.js, lib/services, lib/components/utilities.dart.</Text>
        </Stack>

        <Stack gap={10}>
          <H2>Firestore layout</H2>
          <Table
            headers={["Path", "Holds", "Written by"]}
            rows={[
              [<Code>users/{"{uid}"}</Code>, "Profile, language, theme, blocked list", "Sign-in, Settings"],
              [<Code>users/{"{uid}"}/conversations/{"{cid}"}</Code>, "incomingLanguage, outgoingLanguage", "Languages, createConversation"],
              [<Code>conversations/{"{cid}"}</Code>, "participants, timestamp", "Search, every new message"],
              [<Code>…/messages/{"{id}"}</Code>, "senderId, text, timestamp", "Chat"],
              [<Code>…/transcribedMessages/{"{id}"}</Code>, "Call caption lines", "Video call"],
            ]}
            framed
          />
          <Text size="small" tone="quaternary">
            Source: lib/database/anychat_user.dart and conversation_info.dart. Access is governed by firestore.rules.
          </Text>
        </Stack>
      </Grid>
    </Stack>
  );
}
