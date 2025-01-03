import { Receive, Send } from "@enums/events"
import { DebugEventCallback } from "@typings/events"
import { ReceiveEvent, SendEvent } from "./eventsHandlers"
import { convertImage } from "./txdToBase64"
import { TIDInfo, TIDTypes } from "@typings/id"
import { ID_INFO, ID_TYPE, ID_TYPES } from "@stores/stores"
import { get } from "svelte/store"

const AlwaysListened: DebugEventCallback[] = [
    {
        action: Receive.cardData,
        handler: (data: TIDInfo) => {

            if (!data) {
                ID_INFO.set(null);
                return;
            }

            const idType = data.idType
            if (!idType) {
                console.error('No ID Type found in card types config.');
                return;
            };

            const idTypes = get(ID_TYPES);

            data.imageURL = 'nui://bl_idcard/web/mugshots/' + data.imageURL + '.png'

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
        action: Receive.requestBaseUrl,
        handler: async (txd: string) => {
            const baseUrl = await convertImage(txd);
            SendEvent(Send.resolveBaseUrl, baseUrl);
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