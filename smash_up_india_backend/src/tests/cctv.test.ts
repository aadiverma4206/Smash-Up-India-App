import { encryptSecret, decryptSecret } from "../utils/crypto.utils.js";

describe("CCTV Security & Stream Encryption Tests", () => {
  it("should encrypt and decrypt camera RTSP credentials correctly", () => {
    const rawRtsp = "rtsp://admin:securePass123@192.168.1.100:554/stream1";
    const encrypted = encryptSecret(rawRtsp);

    expect(encrypted).not.toBe(rawRtsp);
    expect(encrypted).toContain(":");

    const decrypted = decryptSecret(encrypted);
    expect(decrypted).toBe(rawRtsp);
  });
});
