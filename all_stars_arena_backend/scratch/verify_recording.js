import jwt from 'jsonwebtoken';
import fs from 'fs';
import path from 'path';

const JWT_SECRET = process.env.JWT_SECRET || 'supersecret_all_stars_arena_access_key_2026';
const token = jwt.sign(
  { id: 'usr_fb7881ea325c8ef7', roleId: 2, email: 'manager@test.com' },
  JWT_SECRET,
  { expiresIn: '1h' }
);

async function testWorkflow() {
  const matchId = 'gam_4045b1f276714f4f';
  console.log('1. Testing POST /api/matches/start...');
  const startRes = await fetch('http://127.0.0.1:5000/api/matches/start', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
    body: JSON.stringify({
      matchId,
      channel: 1,
      durationSeconds: 10
    })
  });
  const startData = await startRes.json();
  console.log('Start response:', JSON.stringify(startData, null, 2));

  console.log('\n2. Waiting 3 seconds for video frames capture...');
  await new Promise(r => setTimeout(r, 3000));

  console.log('\n3. Checking GET /api/matches/' + matchId + '/recording-status...');
  const statusRes = await fetch(`http://127.0.0.1:5000/api/matches/${matchId}/recording-status`);
  const statusData = await statusRes.json();
  console.log('Status response:', JSON.stringify(statusData, null, 2));

  console.log('\n4. Testing POST /api/matches/stop...');
  const stopRes = await fetch('http://127.0.0.1:5000/api/matches/stop', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
    body: JSON.stringify({
      matchId
    })
  });
  const stopData = await stopRes.json();
  console.log('Stop response:', JSON.stringify(stopData, null, 2));

  if (stopData.data?.videoUrl) {
    const videoUrl = `http://127.0.0.1:5000${stopData.data.videoUrl}`;
    console.log(`\n5. Testing HTTP byte-range request to: ${videoUrl}...`);
    const rangeRes = await fetch(videoUrl, {
      headers: {
        'Range': 'bytes=0-1023'
      }
    });
    console.log('Range HTTP status:', rangeRes.status);
    console.log('Content-Type:', rangeRes.headers.get('content-type'));
    console.log('Content-Range:', rangeRes.headers.get('content-range'));
    console.log('Content-Length:', rangeRes.headers.get('content-length'));
    console.log('Accept-Ranges:', rangeRes.headers.get('accept-ranges'));

    const buf = await rangeRes.arrayBuffer();
    console.log('Bytes received:', buf.byteLength);

    console.log('\n6. Testing HEAD request...');
    const headRes = await fetch(videoUrl, { method: 'HEAD' });
    console.log('HEAD status:', headRes.status);
    console.log('HEAD Content-Length:', headRes.headers.get('content-length'));
  }
}

testWorkflow().catch(console.error);
