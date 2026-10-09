import logging

import httpx

from ..config import settings

logger = logging.getLogger(__name__)

FAST2SMS_URL = "https://www.fast2sms.com/dev/bulkV2"


def send_otp_sms(mobile: str, otp: str) -> bool:
    """Send OTP via SMS. Returns True if sent successfully."""

    if not settings.fast2sms_api_key:
        logger.warning("FAST2SMS_API_KEY not set — OTP not sent. Check server logs for OTP.")
        return False

    try:
        response = httpx.post(
            FAST2SMS_URL,
            headers={"authorization": settings.fast2sms_api_key},
            data={
                "route": "otp",
                "variables_values": otp,
                "flash": "0",
                "numbers": mobile,
            },
            timeout=10,
        )

        result = response.json()
        if response.status_code == 200 and result.get("return"):
            logger.info("OTP sent to %s via Fast2SMS (request_id: %s)",
                        mobile, result.get("request_id"))
            return True
        else:
            logger.error("Fast2SMS error: %s", result.get("message", response.text))
            return False

    except httpx.TimeoutException:
        logger.error("Fast2SMS timeout for %s", mobile)
        return False
    except Exception as e:
        logger.error("SMS send failed for %s: %s", mobile, e)
        return False


def send_message_sms(mobile: str, message: str) -> bool:
    """Send a text SMS (order updates etc)."""

    if not settings.fast2sms_api_key:
        logger.warning("FAST2SMS_API_KEY not set — SMS not sent.")
        return False

    try:
        response = httpx.post(
            FAST2SMS_URL,
            headers={"authorization": settings.fast2sms_api_key},
            data={
                "route": "q",  # Quick transactional route
                "message": message,
                "flash": "0",
                "numbers": mobile,
            },
            timeout=10,
        )

        result = response.json()
        if response.status_code == 200 and result.get("return"):
            logger.info("SMS sent to %s", mobile)
            return True
        else:
            logger.error("Fast2SMS error: %s", result.get("message", response.text))
            return False

    except Exception as e:
        logger.error("SMS send failed for %s: %s", mobile, e)
        return False
