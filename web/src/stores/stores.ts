import { TIDInfo, TIDType, TIDTypes } from '@typings/id';
import { IsEnvBrowser } from '@utils/eventsHandlers';
import { get, writable } from 'svelte/store';


export const CONFIG = writable<any>({

    /** Fallback resource name for when the resource name cannot be found. */
    fallbackResourceName: 'debug',

    /** Whether the escape key should make visibility false. */
    allowEscapeKey: true,
});

/**
 * The name of the resource. This is used for the resource manifest.
 * @type {Writable<string>}
 */
export const RESOURCE_NAME = writable<string>(
    (window as any).GetParentResourceName
        ? (window as any).GetParentResourceName()
        : get(CONFIG).DEBUG_RESOURCE_NAME,
);

/**
 * Whether the current environment is the browser or the client.
 * @type {Writable<boolean>}
 */
export const IS_BROWSER = writable<boolean>(!(window as any).invokeNative);

/**
 * Whether the debug menu is visible or not.
 * @type {Writable<boolean>}
 */
export const VISIBLE = writable<boolean>(false);


export const ID_INFO = writable<TIDInfo>(null);

export const ID_TYPES = writable<TIDTypes>(null);

export const ID_TYPE = writable<TIDType>(null);