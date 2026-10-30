"use strict";

const {test, before, after, beforeEach} = require("node:test");
const assert = require("node:assert/strict");
const {
  addDoc, arrayUnion, collection, deleteDoc, doc, documentId, getDoc, getDocs,
  limit, orderBy, query, runTransaction, serverTimestamp, setDoc, updateDoc,
  where, writeBatch,
} = require("firebase/firestore");
const {
  assertFails, assertSucceeds, startEnv, seed, readAsAdmin, dbAs, profile,
} = require("../support/helpers");

let env;

before(async () => {
  env = await startEnv("chat");
});

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await seed(env, {
    "users/alice": profile("Alice", "en"),
    "users/bob": profile("Bob", "fr"),
    "users/carol": profile("Carol", "es"),
    "users/mallory": profile("Mallory", "de"),
  });
});

/**
 * Mirrors AnyChatUser.createConversation: add the conversation, then one
 * transaction per participant to initialize their conversation info.
 *
 * @param {*} db Firestore as the creating user.
 * @param {string} me The creator's uid.
 * @param {string} peer The other participant's uid.
 * @return {Promise<string>} The new conversation id.
 */
async function createConversation(db, me, peer) {
  const conversation = await addDoc(collection(db, "conversations"), {
    participants: [peer, me],
    timestamp: serverTimestamp(),
  });
  const mine = doc(db, `users/${me}/conversations/${conversation.id}`);
  const theirs = doc(db, `users/${peer}/conversations/${conversation.id}`);
  await runTransaction(db, async (tx) => {
    await tx.get(doc(db, `users/${me}`));
    tx.set(mine, {incomingLanguage: "en", outgoingLanguage: "fr"});
  });
  await runTransaction(db, async (tx) => {
    await tx.get(doc(db, `users/${peer}`));
    tx.set(theirs, {incomingLanguage: "fr", outgoingLanguage: "en"});
  });
  await getDoc(mine);
  await getDoc(conversation);
  return conversation.id;
}

/**
 * Mirrors AnyChatUser.addMessageToConversation for a normal thread.
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

/**
 * Seeds a two-person normal conversation with both info docs.
 *
 * @param {string} cid Conversation id.
 * @param {Array<string>} participants Member uids.
 * @return {Promise<void>} Resolves when seeded.
 */
async function seedConversation(cid, participants) {
  const docs = {
    [`conversations/${cid}`]: {participants, timestamp: new Date()},
  };
  for (const uid of participants) {
    docs[`users/${uid}/conversations/${cid}`] =
        {incomingLanguage: "en", outgoingLanguage: "en"};
  }
  await seed(env, docs);
}

test("createConversation flow succeeds and both members can read it",
    async () => {
      const alice = dbAs(env, "alice");
      const cid = await assertSucceeds(
          createConversation(alice, "alice", "bob"));

      const bob = dbAs(env, "bob");
      await assertSucceeds(getDoc(doc(bob, `conversations/${cid}`)));
      await assertSucceeds(getDoc(doc(bob, `users/bob/conversations/${cid}`)));
      assert.deepEqual(await readAsAdmin(env, `users/bob/conversations/${cid}`),
          {incomingLanguage: "fr", outgoingLanguage: "en"});
    });

test("conversation list and id-batch queries work for members", async () => {
  await seedConversation("c1", ["alice", "bob"]);
  await seedConversation("c2", ["alice", "carol"]);
  const alice = dbAs(env, "alice");

  const listed = await assertSucceeds(getDocs(query(
      collection(alice, "conversations"),
      where("participants", "array-contains", "alice"),
      orderBy("timestamp", "asc"))));
  assert.equal(listed.size, 2);

  const batch = await assertSucceeds(getDocs(query(
      collection(alice, "conversations"),
      where(documentId(), "in", ["c1", "c2"]))));
  assert.equal(batch.size, 2);

  const infos = await assertSucceeds(
      getDocs(collection(alice, "users/alice/conversations")));
  assert.equal(infos.size, 2);
});

test("outsiders cannot read conversations, messages, or list them",
    async () => {
      await seedConversation("c1", ["alice", "bob"]);
      await seed(env, {"conversations/c1/messages/m1": {
        senderId: "alice", text: "hi", timestamp: new Date()}});
      const mallory = dbAs(env, "mallory");

      await assertFails(getDoc(doc(mallory, "conversations/c1")));
      await assertFails(getDocs(collection(mallory, "conversations")));
      await assertFails(getDocs(query(collection(mallory, "conversations"),
          where(documentId(), "in", ["c1"]))));
      await assertFails(getDocs(collection(mallory, "conversations/c1/messages")));
      await assertFails(getDocs(
          collection(mallory, "conversations/c1/transcribedMessages")));
      await assertFails(getDocs(collection(mallory, "users/alice/conversations")));
      await assertFails(getDoc(doc(mallory, "users/alice/conversations/c1")));

      const anonymous = dbAs(env, null);
      await assertFails(getDoc(doc(anonymous, "conversations/c1")));
      await assertFails(getDoc(doc(anonymous, "users/alice")));
    });

test("members send and read messages; latest-message query works",
    async () => {
      await seedConversation("c1", ["alice", "bob"]);
      const alice = dbAs(env, "alice");
      await assertSucceeds(sendMessage(alice, "c1",
          {senderId: "alice", text: "bonjour"}));

      const bob = dbAs(env, "bob");
      const all = await assertSucceeds(getDocs(query(
          collection(bob, "conversations/c1/messages"),
          orderBy("timestamp", "asc"))));
      assert.equal(all.size, 1);
      const latest = await assertSucceeds(getDocs(query(
          collection(bob, "conversations/c1/messages"),
          orderBy("timestamp", "desc"), limit(1))));
      assert.equal(latest.docs[0].data().text, "bonjour");
    });

test("messages cannot forge senders, SMS markers, or be edited", async () => {
  await seedConversation("c1", ["alice", "bob"]);
  await seed(env, {"conversations/c1/messages/m1": {
    senderId: "alice", text: "hi", timestamp: new Date()}});
  const alice = dbAs(env, "alice");
  const mallory = dbAs(env, "mallory");

  await assertFails(sendMessage(alice, "c1", {senderId: "bob", text: "x"}));
  await assertFails(sendMessage(alice, "c1",
      {senderId: "alice", text: "x", channel: "sms"}));
  await assertFails(sendMessage(alice, "c1",
      {senderId: "alice", text: "x", channel: "sms", smsStatus: "pending"}));
  await assertFails(sendMessage(alice, "c1",
      {senderId: "alice", text: "x", channel: "sms-inbound"}));
  await assertFails(sendMessage(alice, "c1",
      {senderId: "alice", text: "x", smsProviderId: "SM1"}));
  await assertFails(setDoc(doc(alice, "conversations/c1/messages/m2"),
      {senderId: "alice", text: "x", timestamp: new Date(0)}));
  await assertFails(sendMessage(mallory, "c1",
      {senderId: "mallory", text: "x"}));
  await assertFails(updateDoc(doc(alice, "conversations/c1/messages/m1"),
      {text: "edited"}));
  await assertFails(updateDoc(doc(alice, "conversations/c1/messages/m1"),
      {smsStatus: "sent"}));
  await assertFails(deleteDoc(doc(alice, "conversations/c1/messages/m1")));
});

test("conversation fields cannot be hijacked into SMS or rewritten",
    async () => {
      await seedConversation("c1", ["alice", "bob"]);
      const alice = dbAs(env, "alice");
      const mallory = dbAs(env, "mallory");
      const ref = doc(alice, "conversations/c1");

      await assertFails(updateDoc(ref, {smsOwner: "alice"}));
      await assertFails(updateDoc(ref, {smsContact: "+15550100"}));
      await assertFails(updateDoc(ref, {participants: ["alice", "mallory"]}));
      await assertFails(updateDoc(ref, {participants: ["alice"]}));
      await assertFails(updateDoc(ref,
          {participants: ["alice", "bob", "carol", "mallory"]}));
      await assertFails(updateDoc(ref,
          {participants: ["alice", "bob", "sms:+15550100"]}));
      await assertFails(updateDoc(ref, {timestamp: new Date(0)}));
      await assertFails(updateDoc(doc(mallory, "conversations/c1"),
          {participants: arrayUnion("mallory")}));
      await assertFails(deleteDoc(ref));
    });

test("conversation creation must include the creator and no SMS shape",
    async () => {
      const alice = dbAs(env, "alice");
      const conversations = collection(alice, "conversations");

      await assertFails(addDoc(conversations,
          {participants: ["bob", "carol"], timestamp: serverTimestamp()}));
      await assertFails(addDoc(conversations,
          {participants: ["alice", "alice"], timestamp: serverTimestamp()}));
      await assertFails(addDoc(conversations, {
        participants: ["sms:+15550100", "alice"], timestamp: serverTimestamp(),
      }));
      await assertFails(addDoc(conversations, {
        participants: ["bob", "alice"], timestamp: serverTimestamp(),
        smsOwner: "alice",
      }));
      await assertFails(setDoc(doc(alice, "conversations/sms-alice-15550100"),
          {participants: ["bob", "alice"], timestamp: serverTimestamp()}));
      await assertFails(addDoc(collection(dbAs(env, null), "conversations"),
          {participants: ["bob", "alice"], timestamp: serverTimestamp()}));
    });

test("peers may initialize, but never overwrite, each other's settings",
    async () => {
      await seedConversation("c1", ["alice", "bob"]);
      await seed(env, {"conversations/c2": {
        participants: ["alice", "bob"], timestamp: new Date()}});
      const alice = dbAs(env, "alice");
      const mallory = dbAs(env, "mallory");

      await assertSucceeds(setDoc(doc(alice, "users/bob/conversations/c2"),
          {incomingLanguage: "fr", outgoingLanguage: "en"}));
      await assertFails(setDoc(doc(alice, "users/bob/conversations/c1"),
          {incomingLanguage: "de", outgoingLanguage: "de"}));
      await assertFails(updateDoc(doc(alice, "users/bob/conversations/c1"),
          {incomingLanguage: "de"}));
      await assertFails(deleteDoc(doc(alice, "users/bob/conversations/c1")));
      await assertFails(setDoc(doc(alice, "users/carol/conversations/c1"),
          {incomingLanguage: "es", outgoingLanguage: "en"}));
      await assertFails(setDoc(doc(mallory, "users/mallory/conversations/c1"),
          {incomingLanguage: "es", outgoingLanguage: "en"}));
      await assertFails(setDoc(doc(mallory, "users/carol/conversations/c1"),
          {incomingLanguage: "es", outgoingLanguage: "en"}));
      await assertFails(setDoc(doc(alice, "users/alice/conversations/c9"),
          {incomingLanguage: "es", outgoingLanguage: "en"}));
      await assertFails(updateDoc(doc(alice, "users/alice/conversations/c1"),
          {incomingLanguage: "es", note: "extra"}));
    });

test("language preference update in a transaction succeeds", async () => {
  await seedConversation("c1", ["alice", "bob"]);
  const alice = dbAs(env, "alice");
  await assertSucceeds(runTransaction(alice, async (tx) => {
    await tx.get(doc(alice, "users/alice"));
    tx.update(doc(alice, "users/alice/conversations/c1"),
        {incomingLanguage: "ja"});
  }));
  assert.equal(
      (await readAsAdmin(env, "users/alice/conversations/c1")).incomingLanguage,
      "ja");
});

test("addUserToConversation flow succeeds for a member", async () => {
  await seedConversation("c1", ["alice", "bob"]);
  const alice = dbAs(env, "alice");
  const conversationRef = doc(alice, "conversations/c1");

  await assertSucceeds(runTransaction(alice, async (tx) => {
    const snap = await tx.get(conversationRef);
    tx.update(conversationRef,
        {participants: [...snap.data().participants, "carol"]});
    tx.set(doc(collection(conversationRef, "messages")), {
      timestamp: serverTimestamp(),
      senderId: "alice",
      text: "Alice has added Carol to the conversation",
    });
  }));
  const carolInfo = doc(alice, "users/carol/conversations/c1");
  await assertSucceeds(runTransaction(alice, async (tx) => {
    await tx.get(carolInfo);
    tx.set(carolInfo, {incomingLanguage: "es", outgoingLanguage: "en"});
  }));

  const carol = dbAs(env, "carol");
  await assertSucceeds(getDoc(doc(carol, "conversations/c1")));
  await assertSucceeds(getDocs(collection(carol, "conversations/c1/messages")));
});

test("leaveConversation flow: members leave, last member deletes",
    async () => {
      await seedConversation("c1", ["alice", "bob"]);

      /**
       * Mirrors AnyChatUser.leaveConversation for a normal thread.
       *
       * @param {string} uid The leaving member.
       * @return {Promise<void>} Resolves when done.
       */
      async function leave(uid) {
        const db = dbAs(env, uid);
        const conversationRef = doc(db, "conversations/c1");
        await runTransaction(db, async (tx) => {
          tx.delete(doc(db, `users/${uid}/conversations/c1`));
        });
        await runTransaction(db, async (tx) => {
          const snap = await tx.get(conversationRef);
          const remaining =
              snap.data().participants.filter((id) => id !== uid);
          if (remaining.length === 0) {
            tx.delete(conversationRef);
            return;
          }
          tx.update(conversationRef, {participants: remaining});
          tx.set(doc(collection(conversationRef, "messages")), {
            timestamp: serverTimestamp(),
            senderId: uid,
            text: "This person has left the conversation.",
          });
        });
      }

      await assertSucceeds(leave("alice"));
      const alice = dbAs(env, "alice");
      await assertFails(getDoc(doc(alice, "conversations/c1")));
      await assertFails(sendMessage(alice, "c1",
          {senderId: "alice", text: "still here?"}));
      assert.deepEqual(
          (await readAsAdmin(env, "conversations/c1")).participants, ["bob"]);

      await assertSucceeds(leave("bob"));
      assert.equal(await readAsAdmin(env, "conversations/c1"), null);
    });

test("transcribed messages: members add, read, and clear", async () => {
  await seedConversation("c1", ["alice", "bob"]);
  const alice = dbAs(env, "alice");
  const bob = dbAs(env, "bob");
  const mallory = dbAs(env, "mallory");
  const transcripts = collection(alice, "conversations/c1/transcribedMessages");

  await assertSucceeds(runTransaction(alice, async (tx) => {
    await tx.get(doc(alice, "conversations/c1"));
    tx.set(doc(transcripts), {
      timestamp: serverTimestamp(), senderId: "alice", text: "hello",
    });
  }));
  await assertFails(addDoc(
      collection(bob, "conversations/c1/transcribedMessages"),
      {timestamp: serverTimestamp(), senderId: "alice", text: "forged"}));
  await assertFails(addDoc(
      collection(mallory, "conversations/c1/transcribedMessages"),
      {timestamp: serverTimestamp(), senderId: "mallory", text: "x"}));

  const listed = await assertSucceeds(getDocs(query(
      collection(bob, "conversations/c1/transcribedMessages"),
      orderBy("timestamp", "asc"))));
  assert.equal(listed.size, 1);

  const snapshot = await getDocs(
      collection(bob, "conversations/c1/transcribedMessages"));
  const batch = writeBatch(bob);
  snapshot.docs.forEach((d) => batch.delete(d.ref));
  await assertSucceeds(batch.commit());
});
