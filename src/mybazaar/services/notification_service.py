import logging

from ..config import settings
from .sms_service import send_message_sms

logger = logging.getLogger(__name__)


def send_sms(mobile: str, message: str):
    if settings.app_env == "development":
        logger.info("[DEV SMS] To: %s | Message: %s", mobile, message)
        return True

    return send_message_sms(mobile, message)


def notify_order_placed(mobile: str, order_number: str):
    send_sms(mobile, f"Your order {order_number} has been placed. Payment: Cash on Delivery.")


def notify_order_status(mobile: str, order_number: str, status: str):
    status_messages = {
        "CONFIRMED": f"Your order {order_number} has been confirmed.",
        "PACKED": f"Your order {order_number} has been packed and is ready for dispatch.",
        "OUT_FOR_DELIVERY": f"Your order {order_number} is out for delivery. Keep cash ready.",
        "DELIVERED": f"Your order {order_number} has been delivered. Thank you!",
        "CANCELLED": f"Your order {order_number} has been cancelled.",
    }
    message = status_messages.get(status, f"Your order {order_number} status: {status}")
    send_sms(mobile, message)
