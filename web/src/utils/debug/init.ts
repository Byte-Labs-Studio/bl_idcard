import { DebugAction } from '@typings/events'
import { toggleVisible } from './visibility'
import { ID_INFO } from '@stores/stores'

/**
 * The initial debug actions to run on startup
 */
const InitDebug: DebugAction[] = [
    {
        label: 'Visible',
        action: () => toggleVisible(true),
        delay: 500,
    },
    {
        label: 'Init Info',
        action: () => {
            ID_INFO.set({
                id: '123456',
                dob: '01/01/1970',
                firstName: 'John',
                lastName: 'Doe',
                sex: 'M',
            })
        },
        delay: 0,
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
