import { Receive } from "@enums/events"
import { DebugEventCallback } from "@typings/events"
import { ReceiveEvent } from "./eventsHandlers"
import { TIDInfo, TIDTypes } from "@typings/id"
import { ID_INFO, ID_TYPE, ID_TYPES } from "@stores/stores"
import { get } from "svelte/store"

const AlwaysListened: DebugEventCallback[] = [
    {
        action: Receive.cardData,
        handler: (data: TIDInfo) => {

            const idType = data.idType
            if (!idType) {
                console.error('No ID Type found in card types config.');
                return;
            };

            const idTypes = get(ID_TYPES);

            if (!idTypes) {
                console.error('No ID Types config.');
                return;
            }

            const idTypeConfig = idTypes[idType];

            if (!idTypeConfig) {
                console.error(`No ID Type config for ${idType}.`);
                return;
            }

            const docStyles = document.documentElement.style;

            // set css variables
            docStyles.setProperty('--text', idTypeConfig.textColour);
            docStyles.setProperty('--title', idTypeConfig.titleColour);
            docStyles.setProperty('--bg', idTypeConfig.bgColour);
            docStyles.setProperty('--bg-secondary', idTypeConfig.bgColourSecondary);

            ID_TYPE.set(idTypeConfig);

            ID_INFO.set(data);
        }
    },
    {
        action: Receive.config,
        handler: (data: TIDTypes) => {
            ID_TYPES.set(data);
        }
    
    }
]

export default AlwaysListened



export function InitialiseListen() {
    for (const debug of AlwaysListened) {
        ReceiveEvent(debug.action, debug.handler);
    }
}