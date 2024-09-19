import os

layer_string = "HELLO FROM"


def get_test_key():
    return os.getenv("TEST_KEY")


def get_bye_string():
    return "BYE STRING BYE"


def get_async_client():
    from hikerapi import AsyncClient

    hiker_api_key = os.getenv("HIKER_API_KEY")
    return AsyncClient(hiker_api_key)
