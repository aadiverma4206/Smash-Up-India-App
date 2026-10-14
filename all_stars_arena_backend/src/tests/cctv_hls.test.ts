import { CctvService } from '../modules/cctv/cctv.service.js';
import { CctvDiscoveryService } from '../services/cctvDiscovery.service.js';

describe('CCTV Live RTSP Direct Playback Unit Tests', () => {
  it('creates authorized live RTSP session for Manager (roleId=2)', async () => {
    // Pass empty userId so audit_logs records admin_id as null without violating FK constraint in test DB
    const session = await CctvService.createLiveSession('', 2, 1, 'sub');
    expect(session).toHaveProperty('sessionId');
    expect(session.channel).toBe(1);
    expect(session.streamType).toBe('sub');
    expect(session.rtspUrl).toContain('rtsp://');
    expect(session.playbackUrl).toContain('rtsp://');
  });

  it('rejects live session creation for Player role (roleId=3)', async () => {
    await expect(
      CctvService.createLiveSession('', 3, 1, 'sub')
    ).rejects.toThrow('Forbidden');
  });

  it('rejects invalid channel numbers (< 1 or > 16)', async () => {
    await expect(
      CctvService.createLiveSession('', 2, 0, 'sub')
    ).rejects.toThrow('Invalid channel');
    await expect(
      CctvService.createLiveSession('', 2, 17, 'sub')
    ).rejects.toThrow('Invalid channel');
  });

  it('discovers camera channels and returns valid channel configuration', async () => {
    const cameras = await CctvDiscoveryService.discoverCameras(true);
    expect(cameras).toBeInstanceOf(Array);
    expect(cameras.length).toBeGreaterThan(0);
    expect(cameras[0]).toHaveProperty('id');
    expect(cameras[0]).toHaveProperty('channel');
    expect(cameras[0]).toHaveProperty('status');
  }, 15000);
});
