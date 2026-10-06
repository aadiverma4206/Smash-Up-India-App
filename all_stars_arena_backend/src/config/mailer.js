import { Resend } from 'resend';
import { env } from './env.js';
import { logger } from './logger.js';

const resend = env.RESEND_API_KEY ? new Resend(env.RESEND_API_KEY) : null;

export const sendEmail = async (to, subject, html) => {
  if (resend && env.RESEND_API_KEY && !env.RESEND_API_KEY.includes('dummy')) {
    try {
      const { data, error } = await resend.emails.send({
        from: env.EMAIL_FROM,
        to,
        subject,
        html,
      });

      if (error) {
        logger.error({ error }, `❌ [Resend Error] Email send failed to ${to}`);
        return false;
      }

      logger.info(`✅ [Resend Success] Email sent to ${to} (ID: ${data?.id})`);
      return true;
    } catch (err) {
      logger.error({ err }, `❌ [Resend Exception] Error sending email to ${to}`);
      return false;
    }
  }

  logger.info(`\n========================================`);
  logger.info(`📧 [EMAIL LOG - DEV] To: ${to} | Subject: ${subject}`);
  logger.info(`========================================\n`);
  return true;
};
