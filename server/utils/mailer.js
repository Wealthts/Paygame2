const nodemailer = require('nodemailer');

let transporter = null;

function getTransporter() {
    if (transporter) return transporter;

    const { SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS } = process.env;

    if (!SMTP_HOST || !SMTP_USER || !SMTP_PASS) {
        throw new Error('SMTP is not configured (SMTP_HOST / SMTP_USER / SMTP_PASS)');
    }

    const port = Number(SMTP_PORT) || 465;

    transporter = nodemailer.createTransport({
        host: SMTP_HOST,
        port,
        secure: port === 465, // 465 = SSL, 587 = STARTTLS
        auth: { user: SMTP_USER, pass: SMTP_PASS }
    });

    return transporter;
}

function escapeHtml(text) {
    return String(text).replace(/[&<>"']/g, (c) => ({
        '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
    }[c]));
}

async function sendOtpEmail({ to, otp, displayName, expiresMinutes }) {
    const from = process.env.MAIL_FROM || `PayGame <${process.env.SMTP_USER}>`;
    const name = escapeHtml(displayName || 'ผู้ใช้งาน');

    await getTransporter().sendMail({
        from,
        to,
        subject: 'PayGame Password Reset OTP',
        text:
            `Hello ${displayName || 'User'},\n\n` +
            `Your OTP code is ${otp}.\n` +
            `This code is valid for ${expiresMinutes} minutes and can only be used once.\n\n` +
            `If you did not request a password reset, please ignore this email.`,
        html:
            `<div style="font-family:Arial,sans-serif;max-width:480px;margin:auto">` +
            `<h2 style="color:#b71c1c">PayGame</h2>` +
            `<p>Hello ${name},</p>` +
            `<p>Your OTP code for resetting your password is:</p>` +
            `<p style="font-size:32px;font-weight:bold;letter-spacing:8px">${otp}</p>` +
            `<p>This code is valid for ${expiresMinutes} minutes and can only be used once.</p>` +
            `<p style="color:#777;font-size:12px">If you did not request a password reset, please ignore this email.</p>` +
            `</div>`
    });
}

module.exports = { sendOtpEmail };
