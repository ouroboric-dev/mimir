import { test, expect, type APIRequestContext } from '@playwright/test';

const password = 'correct horse';
let n = 0;
const fresh = () => `p${process.pid}-${Date.now()}-${n++}@example.com`;

async function signUp(request: APIRequestContext, email: string) {
  const res = await request.post('/api/signup', { data: { email, password } });
  expect(res.status()).toBe(201);
}

test('sign up then log in', async ({ page, request }) => {
  const email = fresh();
  await page.goto('/');
  await page.getByLabel('Email').fill(email);
  await page.getByLabel('Password').fill(password);
  await page.getByRole('button', { name: 'Sign up' }).click();
  await expect(page.getByRole('button', { name: 'Log out' })).toBeVisible();
  await page.getByRole('button', { name: 'Log out' }).click();
  await page.getByLabel('Email').fill(email);
  await page.getByLabel('Password').fill(password);
  await page.getByRole('button', { name: 'Log in' }).click();
  await expect(page.getByRole('button', { name: 'Log out' })).toBeVisible();
  const wrong = await request.post('/api/login', { data: { email, password: 'wrong wrong' } });
  expect(wrong.status()).toBe(401);
});

test('a short password is refused', async ({ request }) => {
  const res = await request.post('/api/signup', { data: { email: fresh(), password: 'short' } });
  expect(res.status()).toBe(400);
});

test('log out ends the session', async ({ request }) => {
  await signUp(request, fresh());
  expect((await request.get('/api/notes')).status()).toBe(200);
  expect((await request.post('/api/logout')).status()).toBe(204);
  expect((await request.get('/api/notes')).status()).toBe(401);
});

test('add and list a note', async ({ page }) => {
  await page.goto('/');
  await page.getByLabel('Email').fill(fresh());
  await page.getByLabel('Password').fill(password);
  await page.getByRole('button', { name: 'Sign up' }).click();
  await page.getByLabel('Note').fill('buy milk');
  await page.getByRole('button', { name: 'Add note' }).click();
  await expect(page.getByRole('listitem').filter({ hasText: 'buy milk' })).toHaveCount(1);
});

test('delete a note', async ({ request }) => {
  await signUp(request, fresh());
  const created = await request.post('/api/notes', { data: { text: 'to delete' } });
  expect(created.status()).toBe(201);
  const { id } = await created.json();
  expect((await request.delete(`/api/notes/${id}`)).status()).toBe(204);
  expect(await (await request.get('/api/notes')).json()).toEqual([]);
});

test('notes need a session', async ({ request }) => {
  expect((await request.get('/api/notes')).status()).toBe(401);
  expect((await request.post('/api/notes', { data: { text: 'x' } })).status()).toBe(401);
  expect((await request.delete('/api/notes/1')).status()).toBe(401);
});

test('another person cannot see or delete my note', async ({ playwright, baseURL }) => {
  const alice = await playwright.request.newContext({ baseURL });
  const bob = await playwright.request.newContext({ baseURL });
  await signUp(alice, fresh());
  await signUp(bob, fresh());
  const created = await alice.post('/api/notes', { data: { text: 'alice secret' } });
  const { id } = await created.json();
  expect(await (await bob.get('/api/notes')).json()).toEqual([]);
  const del = await bob.delete(`/api/notes/${id}`);
  const missing = await bob.delete('/api/notes/does-not-exist');
  expect(del.status()).toBe(404);
  expect(missing.status()).toBe(404);
  expect(await del.text()).toBe(await missing.text());
  const mine = await (await alice.get('/api/notes')).json();
  expect(mine.map((x: { text: string }) => x.text)).toEqual(['alice secret']);
  await alice.dispose();
  await bob.dispose();
});
