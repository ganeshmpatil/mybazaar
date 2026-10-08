from ..config import settings


def send_sms(mobile: str, message: str):
    if settings.app_env == "development":
        print(f"[DEV SMS] To: {mobile} | Message: {message}")
        return True

    # TODO: integrate MSG91 or other SMS gateway
    # import httpx
    # response = httpx.post(...)
    return True


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
