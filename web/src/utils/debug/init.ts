import { DebugAction } from '@typings/events'
import { toggleVisible } from './visibility'
import { ID_INFO, ID_TYPES } from '@stores/stores'
import { DebugEventSend } from '@utils/eventsHandlers'
import { Receive } from '@enums/events'
import { TIDTypes } from '@typings/id'

/**
 * The initial debug actions to run on startup
 */
const InitDebug: DebugAction[] = [
    {
        label: 'Visible',
        action: ()=> toggleVisible(true),
        delay: 500,
    },
    {
        label: 'Init Info',
        action: ()=> {
            DebugEventSend(Receive.cardData, {
                id: '123456',
                dob: '01/01/1970',
                firstName: 'John',
                lastName: 'Doe',
                sex: 'M',
                idType: 'male_id',
                imageURL: 'https://imgur.com/2nL5VV8.png'
            })
        },
        delay: 1,
    },
    {
        label: 'ID Configs',
        action: () => {

            const types: TIDTypes = {
                driver_license: {
                    type: 'driver_license',
                    title: 'SAN ANDREAS',
                    titleColour: '#bdbdbd',
        
                    label: 'DRIVER LICENSE',
                
                    stamp: true,
                    profileStamp: false,
                
                    signature: true,
                
                    bgColour: '#000',
                    bgColourSecondary: '#000',
                
                    textColour: '#FFF',
                },
        
                weapon_license: {
                    type: 'weapon_license',
                    title: 'SAN ANDREAS',
                    titleColour: '#BEBEBE',
        
                    label: 'WEAPON LICENSE',
                
                    stamp: true,
                    profileStamp: false,
                
                    signature: true,
                
                    bgColour: '#460000',
                    bgColourSecondary: '#E90000',
                
                    textColour: '#FFF',
                },
        
                female_id: {
                    type: 'female_id',
                    title: 'SAN ANDREAS',
                    titleColour: '#F97C81',
        
                    label: 'ID CARD',
                
                    stamp: true,
                    profileStamp: true,
                
                    signature: true,
                
                    bgColour: '#f1e6db',
                    bgColourSecondary: '#d3f7ff',
                
                    textColour: '#323443',
                },
                
                male_id: {
                    type: 'male_id',
                    title: 'SAN ANDREAS',
                    titleColour: '#3A84AD',
        
                    label: 'ID CARD',
                
                    stamp: true,
                    profileStamp: true,
                
                    signature: true,
                
                    bgColour: '#F1E6DB',
                    bgColourSecondary: '#D3F7FF',
                
                    textColour: '#323443',
                },
            }

            DebugEventSend<TIDTypes>(Receive.config, types)
        }
    }
]

export default InitDebug


export function InitialiseDebugSenders(): void {
    for (const debug of InitDebug) {
        setTimeout(() => {
            debug.action()
        }, debug.delay || 0)
    }
}
