# This files contains your custom actions which can be used to run
# custom Python code.
#
# See this guide on how to implement these action:
# https://rasa.com/docs/rasa/custom-actions

import json
import re

from rasa_sdk import Action, Tracker
from rasa_sdk.executor import CollectingDispatcher
from rasa_sdk.events import SlotSet
from typing import Any, Text, Dict, List


class ActionAddOrder(Action):

    def name(self) -> Text:
        return "action_order_food"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        with open("menu.json", "r") as file:
            menu = json.load(file)

        current_order = tracker.get_slot('order')
        entities = tracker.latest_message.get('entities', [])
        new_items = set()

        for entity in entities:
            if entity['entity'] == 'food_item':
                food_item = entity['value']
                if any(item.get("name", "").lower() == food_item.lower() for item in menu["items"]):
                    new_items.add(food_item)  # Add the food item to the set
                else:
                    dispatcher.utter_message(
                        text=f" {food_item} is not available. Can I help you with something else?")

        if new_items:
            if not current_order:
                current_order = ', '.join(new_items)
            else:
                current_order += ", " + ', '.join(new_items)
            dispatcher.utter_message(text=f" {' and '.join(new_items)} added to your order.")
            return [SlotSet("order", current_order)]
        else:
            return []


class ActionShowOrder(Action):

    def name(self) -> Text:
        return "action_show_order"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        current_order = tracker.get_slot('order')

        if current_order:
            response = " current order:\n"
            items = current_order.split(", ")
            for item in items:
                response += f"- {item}\n"

            dispatcher.utter_message(text=response)
        else:
            dispatcher.utter_message(text=" order is empty.")

        return []


class ActionShowMenu(Action):

    def name(self) -> Text:
        return "action_show_menu"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        FILE_PATH = 'menu.json'
        response = "The menu:\n"

        with open(FILE_PATH, 'r') as file:
            data = json.load(file)

        items = data['items']

        for item in items:
            name = item['name']
            price = item['price']
            prep_time = item['preparation_time']
            response += f"{name}: costs {price} and its preparation time is {prep_time}\n"
        dispatcher.utter_message(text=response)
        return []


class ActionCheckHours(Action):

    def name(self) -> Text:
        return "action_check_open_hours"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:

        FILE_PATH = 'work_hours.json'

        with open(FILE_PATH, 'r') as file:
            data = json.load(file)

        message = tracker.latest_message.get("text")

        matches = re.findall(r'\b(?:0?1?\d|2[0-4])\b', message)
        if matches:
            user_time = int(matches[0])
        else:
            dispatcher.utter_message(text="no correct number in the message.")
            return []

        current_day = None

        for day in data.keys():
            if day.lower() in message.lower():
                current_day = day
                break
        if not current_day:
            dispatcher.utter_message(text="no day in the message.")
            return []

        if current_day in data:
            open_time = data[current_day]["open"]
            close_time = data[current_day]["close"]
            if close_time > user_time > open_time:
                response = "we are open at that time."
            else:
                response = "we are closed at that time."
        else:
            response = "no information for today's hours."

        dispatcher.utter_message(text=response)
        return []
