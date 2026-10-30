"use strict";

const {test, before, after, beforeEach} = require("node:test");
const assert = require("node:assert/strict");
const {
  addDoc, collection, deleteDoc, doc, getDoc, getDocs, orderBy, query,
  runTransaction, serverTimestamp, setDoc, updateDoc, where,
} = require("firebase/firestore");
const {
  assertFails, assertSucceeds, startEnv, seed, readAsAdmin, dbAs, profile,
} = require("../support/helpers");

const CONTACT = "+15550100";
const ALICE_SMS = "sms-alice-15550100";

let env;

before(async () => {
  env = await startEnv("sms");
});

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await seed(env, {
    "users/alice": profile("Alice", "en"),
    "users/bob": profile("Bob", "fr"),
    "users/mallory": profile("Mallory", "de"),
  });
});

/**
 * Conversation fields the client and bridge write for an SMS thread.
 *
 * @param {string} uid Owner uid.
 * @param {string} contact Canonical E.164 contact.
 * @param {*} timestamp Timestamp value.
 * @return {Object} Conversation data.
 */
function smsConversation(uid, contact, timestamp = serverTimestamp()) {
  return {
    participants: [uid, `sms:${contact}`],
    smsOwner: uid,
    smsContact: contact,
    timestamp,
  };
}

/**
 * Mirrors openSmsConversation: one transaction that reads the info doc,
 * merges the conversation, and initializes the info doc when missing.
 *
 * @param {*} db Firestore as the user.
 * @param {string} uid The user's uid.
 * @param {string} cid Target conversation id.
 * @param {Object} data Conversation fields to merge.
 * @return {Promise<void>} Resolves when the transaction commits.
 */
async function openSms(db, uid, cid, data) {
  const info = doc(db, `users/${uid}/conversations/${cid}`);
  await runTransaction(db, async (tx) => {
    const existing = await tx.get(info);
    tx.set(doc(db, `conversations/${cid}`), data, {merge: true});
    if (!existing.exists()) {
      tx.set(info, {incomingLanguage: "en", outgoingLanguage: "en"});
    }
  });
}

/**
 * Mirrors addMessageToConversation: bump the timestamp and add a message.
 *
 * @param {*} db Firestore as the sender.
 * @param {string} cid Conversation id.
 * @param {Object} message Message fields.
 * @return {Promise<void>} Resolves when the transaction commits.
 */
async function sendMessage(db, cid, message) {
  const conversationRef = doc(db, `conversations/${cid}`);
  await runTransaction(db, async (tx) => {
    await tx.get(conversationRef);
    tx.update(conversationRef, {timestamp: serverTimestamp()});
    tx.set(doc(collection(conversationRef, "messages")), {
      timestamp: serverTimestamp(),
      ...message,
    });
  });
}

const outbound = (text = "hello") => ({
  senderId: "alice", text, channel: "sms", smsStatus: "pending",
});

test("owner opens, reopens, sends, and lists an SMS thread", async () => {
  const alice = dbAs(env, "alice");
  await assertSucceeds(openSms(alice, "alice", ALICE_SMS,
      smsConversation("alice", CONTACT)));
  await assertSucceeds(openSms(alice, "alice", ALICE_SMS,
      smsConversation("alice", CONTACT)));
  await assertSucceeds(sendMessage(alice, ALICE_SMS, outbound()));

  const listed = await assertSucceeds(getDocs(query(
      collection(alice, "conversations"),
      where("participants", "array-contains", "alice"),
      orderBy("timestamp", "asc"))));
  assert.deepEqual(listed.docs.map((d) => d.id), [ALICE_SMS]);
  const messages = await assertSucceeds(getDocs(query(
      collection(alice, `conversations/${ALICE_SMS}/messages`),
      orderBy("timestamp", "asc"))));
  assert.equal(messages.docs[0].data().channel, "sms");
});

test("owner can reopen a bridge-created thread", async () => {
  await seed(env, {
    [`conversations/${ALICE_SMS}`]:
        smsConversation("alice", CONTACT, new Date()),
    [`conversations/${ALICE_SMS}/messages/sms-1`]: {
      senderId: `sms:${CONTACT}`, text: "hi", timestamp: new Date(),
      channel: "sms-inbound", smsProviderId: "SM1", smsReceivedAt: 1,
    },
  });
  const alice = dbAs(env, "alice");
  await assertSucceeds(openSms(alice, "alice", ALICE_SMS,
      smsConversation("alice", CONTACT)));
  await assertSucceeds(
      getDoc(doc(alice, `conversations/${ALICE_SMS}/messages/sms-1`)));
});

test("SMS thread creation requires a deterministic, canonical identity",
    async () => {
      const alice = dbAs(env, "alice");
      const create = (cid, data) =>
        setDoc(doc(alice, `conversations/${cid}`), data);

      await assertFails(create("sms-bob-15550100",
          smsConversation("alice", CONTACT)));
      await assertFails(create("sms-alice-15550199",
          smsConversation("alice", CONTACT)));
      await assertFails(create("sms-alice-15550100",
          smsConversation("alice", "+1 555 0100")));
      await assertFails(create("sms-alice-15550100",
          smsConversation("alice", "15550100")));
      await assertFails(create("sms-alice-15550100", {
        ...smsConversation("alice", CONTACT), smsOwner: "bob"}));
      await assertFails(create("sms-alice-15550100", {
        ...smsConversation("alice", CONTACT),
        participants: ["alice", "sms:+15550199"]}));
      await assertFails(create("sms-alice-15550100", {
        ...smsConversation("alice", CONTACT),
        participants: ["alice", "bob"]}));
      await assertFails(create("sms-alice-15550100", {
        ...smsConversation("alice", CONTACT),
        participants: ["alice", `sms:${CONTACT}`, "bob"]}));
      await assertFails(create("sms-alice-15550100", {
        ...smsConversation("alice", CONTACT), smsStatus: "sent"}));
      await assertFails(addDoc(collection(alice, "conversations"),
          smsConversation("alice", CONTACT)));
      await assertFails(setDoc(
          doc(dbAs(env, null), `conversations/${ALICE_SMS}`),
          smsConversation("alice", CONTACT)));
    });

test("other users cannot read, take over, or post to an SMS thread",
    async () => {
      await seed(env, {
        [`conversations/${ALICE_SMS}`]:
            smsConversation("alice", CONTACT, new Date()),
        [`users/alice/conversations/${ALICE_SMS}`]:
            {incomingLanguage: "en", outgoingLanguage: "en"},
      });
      const mallory = dbAs(env, "mallory");

      await assertFails(getDoc(doc(mallory, `conversations/${ALICE_SMS}`)));
      await assertFails(getDocs(
          collection(mallory, `conversations/${ALICE_SMS}/messages`)));
      await assertFails(openSms(mallory, "mallory", ALICE_SMS,
          smsConversation("mallory", CONTACT)));
      await assertFails(setDoc(doc(mallory, `conversations/${ALICE_SMS}`),
          {smsOwner: "mallory"}, {merge: true}));
      await assertFails(sendMessage(mallory, ALICE_SMS, {
        senderId: "mallory", text: "x", channel: "sms", smsStatus: "pending",
      }));
      await assertFails(deleteDoc(doc(mallory, `conversations/${ALICE_SMS}`)));
      await assertFails(setDoc(
          doc(mallory, `users/alice/conversations/${ALICE_SMS}`),
          {incomingLanguage: "de", outgoingLanguage: "de"}));
      // A user's own thread for the same contact is a separate document.
      await assertSucceeds(openSms(mallory, "mallory", "sms-mallory-15550100",
          smsConversation("mallory", CONTACT)));
    });

test("owner cannot rewrite the SMS identity or add members", async () => {
  await seed(env, {
    [`conversations/${ALICE_SMS}`]:
        smsConversation("alice", CONTACT, new Date()),
  });
  const alice = dbAs(env, "alice");
  const ref = doc(alice, `conversations/${ALICE_SMS}`);

  await assertFails(updateDoc(ref, {smsContact: "+15550199"}));
  await assertFails(updateDoc(ref, {smsOwner: "bob"}));
  await assertFails(updateDoc(ref,
      {participants: ["alice", "sms:+15550199"]}));
  await assertFails(updateDoc(ref,
      {participants: ["alice", `sms:${CONTACT}`, "bob"]}));
  await assertFails(updateDoc(ref, {participants: [`sms:${CONTACT}`]}));
  await assertFails(setDoc(doc(alice, `users/bob/conversations/${ALICE_SMS}`),
      {incomingLanguage: "fr", outgoingLanguage: "en"}));
  await assertSucceeds(updateDoc(ref, {timestamp: serverTimestamp()}));
});

test("SMS messages must be pending outbound sms from the owner", async () => {
  await seed(env, {
    [`conversations/${ALICE_SMS}`]:
        smsConversation("alice", CONTACT, new Date()),
    [`conversations/${ALICE_SMS}/messages/m1`]: {
      ...outbound(), timestamp: new Date()},
  });
  const alice = dbAs(env, "alice");
  const {channel: _c, smsStatus: _s, ...plain} = outbound();

  await assertFails(sendMessage(alice, ALICE_SMS, plain));
  await assertFails(sendMessage(alice, ALICE_SMS,
      {...outbound(), channel: "sms-inbound"}));
  await assertFails(sendMessage(alice, ALICE_SMS,
      {...outbound(), smsStatus: "sent"}));
  await assertFails(sendMessage(alice, ALICE_SMS,
      {...outbound(), smsProviderId: "SM1"}));
  await assertFails(sendMessage(alice, ALICE_SMS,
      {...outbound(), senderId: `sms:${CONTACT}`}));
  await assertFails(sendMessage(alice, ALICE_SMS, outbound("")));
  await assertFails(sendMessage(alice, ALICE_SMS, outbound("x".repeat(1601))));
  await assertSucceeds(sendMessage(alice, ALICE_SMS,
      outbound("x".repeat(1600))));
  const message = doc(alice, `conversations/${ALICE_SMS}/messages/m1`);
  await assertFails(updateDoc(message, {smsStatus: "sent"}));
  await assertFails(updateDoc(message, {text: "changed"}));
  await assertFails(deleteDoc(message));
});

test("owner deletes the thread; only the owner can recreate it", async () => {
  const alice = dbAs(env, "alice");
  await assertSucceeds(openSms(alice, "alice", ALICE_SMS,
      smsConversation("alice", CONTACT)));

  // Mirrors leaveConversation for SMS threads.
  await assertSucceeds(
      deleteDoc(doc(alice, `users/alice/conversations/${ALICE_SMS}`)));
  await assertSucceeds(deleteDoc(doc(alice, `conversations/${ALICE_SMS}`)));
  assert.equal(await readAsAdmin(env, `conversations/${ALICE_SMS}`), null);

  const mallory = dbAs(env, "mallory");
  await assertFails(openSms(mallory, "mallory", ALICE_SMS,
      smsConversation("mallory", CONTACT)));
  await assertFails(openSms(mallory, "mallory", ALICE_SMS,
      smsConversation("alice", CONTACT)));
  await assertSucceeds(openSms(alice, "alice", ALICE_SMS,
      smsConversation("alice", CONTACT)));
  assert.equal(
      (await readAsAdmin(env, `conversations/${ALICE_SMS}`)).smsOwner,
      "alice");
});

test("normal conversations cannot be turned into SMS relays", async () => {
  await seed(env, {
    "conversations/c1": {participants: ["alice", "bob"], timestamp: new Date()},
  });
  const alice = dbAs(env, "alice");

  await assertFails(sendMessage(alice, "c1", outbound()));
  await assertFails(setDoc(doc(alice, "conversations/c1"),
      {smsOwner: "alice", smsContact: CONTACT}, {merge: true}));
  await assertFails(setDoc(doc(alice, "conversations/sms-alice-15550101"),
      {participants: ["alice", "bob"], timestamp: serverTimestamp()}));
});
