"use strict";

const {test, before, after, beforeEach} = require("node:test");
const assert = require("node:assert/strict");
const {
  collection, deleteDoc, doc, getDoc, getDocs, query, runTransaction, setDoc,
  updateDoc, where,
} = require("firebase/firestore");
const {
  assertFails, assertSucceeds, startEnv, seed, dbAs, profile,
} = require("../support/helpers");

let env;

before(async () => {
  env = await startEnv("users");
});

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await seed(env, {
    "users/alice": profile("Alice", "en"),
    "users/bob": profile("Bob", "fr"),
  });
});

test("signed-in users can read profiles and search by name or email",
    async () => {
      const alice = dbAs(env, "alice");
      const users = collection(alice, "users");

      await assertSucceeds(getDoc(doc(alice, "users/bob")));
      await assertSucceeds(getDoc(doc(alice, "users/sms:+15550100")));
      const byName = await assertSucceeds(getDocs(query(users,
          where("displayName", ">=", "Bo"), where("displayName", "<", "Bp"))));
      assert.equal(byName.size, 1);
      const byEmail = await assertSucceeds(getDocs(query(users,
          where("email", ">=", "bob"), where("email", "<", "boc"))));
      assert.equal(byEmail.size, 1);
      const all = await assertSucceeds(getDocs(users));
      assert.equal(all.size, 2);
    });

test("unauthenticated clients cannot read or write profiles", async () => {
  const anonymous = dbAs(env, null);
  await assertFails(getDoc(doc(anonymous, "users/alice")));
  await assertFails(getDocs(collection(anonymous, "users")));
  await assertFails(setDoc(doc(anonymous, "users/eve"), profile("Eve")));
});

test("users create and update only their own profile", async () => {
  const carol = dbAs(env, "carol");
  await assertSucceeds(setDoc(doc(carol, "users/carol"), profile("Carol")));
  await assertFails(setDoc(doc(carol, "users/dave"), profile("Dave")));
  await assertFails(setDoc(doc(carol, "users/carol2"),
      {...profile("Carol"), admin: true}));

  const alice = dbAs(env, "alice");
  const me = doc(alice, "users/alice");
  await assertSucceeds(runTransaction(alice, async (tx) => {
    await tx.get(me);
    tx.update(me, {language: "ja"});
  }));
  await assertSucceeds(updateDoc(me, {
    theme: "dark", notificationsEnabled: true, blockedAccounts: ["bob"],
    photoUrl: "https://example.test/a.png", displayName: "Al",
    email: "al@example.test", emailVerified: true,
  }));
  await assertFails(updateDoc(me, {role: "admin"}));
  await assertFails(updateDoc(doc(alice, "users/bob"), {displayName: "x"}));
  await assertFails(deleteDoc(doc(alice, "users/bob")));
  await assertSucceeds(deleteDoc(me));
});
