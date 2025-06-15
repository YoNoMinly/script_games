import asyncio
from typing import Text, Optional, Any, Dict, Callable, Awaitable

from rasa.core.channels import InputChannel, OutputChannel, UserMessage
from sanic import Blueprint
from slack_sdk import WebClient
from slack_sdk.socket_mode import SocketModeClient
from slack_sdk.socket_mode.request import SocketModeRequest
from slack_sdk.socket_mode.response import SocketModeResponse


class SlackBotWithSocket(OutputChannel):
    @classmethod
    def name(cls) -> Text:
        return "slack_with_socket"

    def __init__(self, socket_client: SocketModeClient,
                 slack_channel: Optional[Text] = None,
                 thread_id: Optional[Text] = None,
                 *args: Any, **kwargs: Any) -> None:
        super().__init__(*args, **kwargs)
        self.socket_client = socket_client
        self.slack_channel = slack_channel
        self.thread_id = thread_id

    async def _post_message(self, channel: Text, **kwargs: Any) -> None:
        self.socket_client.web_client.chat_postMessage(channel=channel, **kwargs)

    async def send_text_message(self, recipient_id: Text, text: Text, **kwargs: Any) -> None:
        recipient = self.slack_channel or recipient_id
        thread_id = self.thread_id or kwargs.get("thread_id")
        for message_part in text.strip().split("\n\n"):
            await self._post_message(
                channel=recipient, as_user=True, text=message_part, type="mrkdwn", thread_ts=thread_id
            )


class SlackWithSocketInput(InputChannel):
    on_new_message: Optional[Callable[[UserMessage], Awaitable[Any]]] = None

    @classmethod
    def name(cls) -> Text:
        return "slack_with_socket"

    @classmethod
    def from_credentials(cls, credentials: Optional[Dict[Text, Any]]) -> InputChannel:
        if not credentials:
            cls.raise_missing_credentials_exception()

        return cls(
            credentials.get("slack_token"),
            credentials.get("slack_app_token"),
            credentials.get("slack_channel"),
            credentials.get("slack_signing_secret", "")
        )

    def __init__(
            self,
            slack_token: Text,
            slack_app_token: Text,
            slack_channel: Optional[Text] = None,
            slack_signing_secret: Text = ""
    ) -> None:
        self.slack_token = slack_token
        self.slack_channel = slack_channel
        self.slack_signing_secret = slack_signing_secret
        self.socket_client = SocketModeClient(app_token=slack_app_token, web_client=WebClient(token=slack_token))
        self.socket_client.socket_mode_request_listeners.append(self._handle_message)
        self.socket_client.connect()
        self.slack_bot_user_id = self.socket_client.web_client.auth_test()["user_id"]

    def _handle_message(self, client: SocketModeClient, req: SocketModeRequest) -> None:
        if req.type == "events_api":
            response = SocketModeResponse(envelope_id=req.envelope_id)
            self.socket_client.send_socket_mode_response(response)

            if req.payload["event"]["type"] == "app_mention" \
                    and req.payload["event"].get("subtype") is None:
                if req.payload["event"]["user"] != self.slack_bot_user_id:
                    thread_id = req.payload["event"].get("thread_ts")
                    parent_user_id = req.payload["event"].get("parent_user_id")
                    if thread_id and parent_user_id != self.slack_bot_user_id:
                        return
                    user_message = UserMessage(req.payload["event"]["text"],
                                               self.get_output_channel(req.payload["event"]["channel"], thread_id),
                                               req.payload["event"]["user"])
                    asyncio.run(self.on_new_message(user_message))

    def blueprint(
            self, on_new_message: Callable[[UserMessage], Awaitable[Any]]
    ) -> Blueprint:
        self.on_new_message = on_new_message
        return Blueprint("slack_with_socket", __name__)

    def get_output_channel(
            self, channel: Optional[Text] = None, thread_id: Optional[Text] = None
    ) -> OutputChannel:
        return SlackBotWithSocket(self.socket_client, channel or self.slack_channel, thread_id=thread_id)
