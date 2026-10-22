const http = require('http');

async function testLogin(email, password) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify({ identifier: email, password: password });
    const req = http.request(
      {
        hostname: '127.0.0.1',
        port: 5000,
        path: '/api/v1/auth/login',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(postData),
        },
      },
      (res) => {
        let body = '';
        res.on('data', chunk => (body += chunk));
        res.on('end', () => {
          resolve({ status: res.statusCode, body: JSON.parse(body) });
        });
      }
    );
    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

async function run() {
  const users = [
    { email: 'player@gmail.com', pass: 'Player@123', label: 'Green Icon (Player)' },
    { email: 'roshan12@gmail.com', pass: 'Roshan@123', label: 'Yellow Icon (Manager)' },
    { email: 'aadiverma4206@gmail.com', pass: 'Admin@123', label: 'Purple Icon (Admin)' },
  ];

  for (const u of users) {
    try {
      const res = await testLogin(u.email, u.pass);
      console.log(`[${u.label}] Login ${res.status === 200 ? '✅ SUCCESS' : '❌ FAILED'}: HTTP ${res.status}`);
      if (res.status === 200) {
        console.log(`   User: ${res.body.data.user.name} | Role: ${res.body.data.user.roleId}`);
      } else {
        console.log(`   Response:`, res.body);
      }
    } catch (e) {
      console.error(`Error logging in ${u.email}:`, e.message);
    }
  }
}

run();
