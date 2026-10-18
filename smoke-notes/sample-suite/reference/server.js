// Reference solution for the smoke-notes sample suite. In memory, no dependencies.
'use strict';
const http = require('node:http');
const crypto = require('node:crypto');

const users = new Map(); // email -> { id, salt, hash }
const sessions = new Map(); // token -> user id
const notes = []; // { id, owner, text }

const page = `<!doctype html><meta charset="utf-8"><title>Notes</title>
<div id="out"><form id="in">
<label>Email <input id="email" type="email"></label>
<label>Password <input id="pw" type="password"></label>
<button type="button" id="up">Sign up</button><button type="button" id="login">Log in</button>
<p id="msg"></p></form>
<div id="app" hidden><button id="logout">Log out</button>
<label>Note <input id="note"></label><button id="add">Add note</button><ul id="list"></ul></div></div>
<script>
const $ = (i) => document.getElementById(i);
const post = (p, b) => fetch(p, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify(b) });
async function show() {
  const r = await fetch('/api/notes');
  $('in').hidden = r.status === 200;
  $('app').hidden = r.status !== 200;
  if (r.status !== 200) return;
  $('list').replaceChildren(...(await r.json()).map((n) => {
    const li = document.createElement('li'); li.append(n.text + ' ');
    const b = document.createElement('button'); b.textContent = 'Delete';
    b.onclick = async () => { await fetch('/api/notes/' + n.id, { method: 'DELETE' }); show(); };
    li.append(b); return li; }));
}
async function auth(path) {
  const r = await post(path, { email: $('email').value, password: $('pw').value });
  $('msg').textContent = r.ok ? '' : 'refused'; show();
}
$('up').onclick = () => auth('/api/signup'); $('login').onclick = () => auth('/api/login');
$('logout').onclick = async () => { await post('/api/logout', {}); show(); };
$('add').onclick = async () => { await post('/api/notes', { text: $('note').value }); $('note').value = ''; show(); };
show();
</script>`;

const hash = (pw, salt) => crypto.scryptSync(pw, salt, 32).toString('hex');
const send = (res, code, body, headers = {}) => {
  res.writeHead(code, { 'content-type': 'application/json', ...headers });
  res.end(body === undefined ? '' : JSON.stringify(body));
};
const userOf = (req) => {
  const m = /(?:^|; )sid=([a-f0-9]+)/.exec(req.headers.cookie || '');
  return m ? sessions.get(m[1]) : undefined;
};
const login = (res, userId, code) => {
  const token = crypto.randomBytes(24).toString('hex');
  sessions.set(token, userId);
  send(res, code, { ok: true }, { 'set-cookie': `sid=${token}; HttpOnly; SameSite=Lax; Path=/` });
};

http.createServer((req, res) => {
  const chunks = [];
  req.on('data', (c) => chunks.push(c));
  req.on('end', () => {
    let body = {};
    try { body = JSON.parse(Buffer.concat(chunks).toString() || '{}'); } catch { return send(res, 400, { error: 'bad json' }); }
    const url = new URL(req.url, 'http://x');
    const p = url.pathname;
    if (req.method === 'GET' && p === '/') {
      res.writeHead(200, { 'content-type': 'text/html; charset=utf-8' });
      return res.end(page);
    }
    if (req.method === 'POST' && p === '/api/signup') {
      const { email, password } = body;
      if (typeof email !== 'string' || !/^[^@\s]+@[^@\s]+$/.test(email) || typeof password !== 'string' || password.length < 8) {
        return send(res, 400, { error: 'bad input' });
      }
      if (users.has(email)) return send(res, 409, { error: 'used' });
      const salt = crypto.randomBytes(8).toString('hex');
      const user = { id: crypto.randomUUID(), salt, hash: hash(password, salt) };
      users.set(email, user);
      return login(res, user.id, 201);
    }
    if (req.method === 'POST' && p === '/api/login') {
      const u = users.get(body.email);
      if (!u || typeof body.password !== 'string' || hash(body.password, u.salt) !== u.hash) return send(res, 401, { error: 'refused' });
      return login(res, u.id, 200);
    }
    if (req.method === 'POST' && p === '/api/logout') {
      const m = /(?:^|; )sid=([a-f0-9]+)/.exec(req.headers.cookie || '');
      if (m) sessions.delete(m[1]);
      return send(res, 204);
    }
    if (p.startsWith('/api/notes')) {
      const me = userOf(req);
      if (!me) return send(res, 401, { error: 'login needed' });
      if (p === '/api/notes' && req.method === 'GET') {
        return send(res, 200, notes.filter((n) => n.owner === me).map(({ id, text }) => ({ id, text })).reverse());
      }
      if (p === '/api/notes' && req.method === 'POST') {
        if (typeof body.text !== 'string' || body.text.length < 1 || body.text.length > 500) return send(res, 400, { error: 'bad text' });
        const note = { id: crypto.randomUUID(), owner: me, text: body.text };
        notes.push(note);
        return send(res, 201, { id: note.id, text: note.text });
      }
      const id = p.slice('/api/notes/'.length);
      if (req.method === 'DELETE' && p.startsWith('/api/notes/')) {
        const i = notes.findIndex((n) => n.id === id && n.owner === me);
        if (i < 0) return send(res, 404, { error: 'not found' });
        notes.splice(i, 1);
        return send(res, 204);
      }
    }
    send(res, 404, { error: 'not found' });
  });
}).listen(3000, '0.0.0.0');
