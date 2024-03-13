import { Receive } from "@enums/events"
import { DebugEventCallback } from "@typings/events"
import { ReceiveEvent } from "./eventsHandlers"
import { TIdInfo } from "@typings/id"
import { ID_INFO } from "@stores/stores"

const AlwaysListened: DebugEventCallback[] = [
    {
        action: Receive.cardData,
        handler: (data: TIdInfo) => {
            ID_INFO.set(data);
        }
    }
]

export default AlwaysListened



export function InitialiseListen() {
    for (const debug of AlwaysListened) {
        ReceiveEvent(debug.action, debug.handler);
    }
}