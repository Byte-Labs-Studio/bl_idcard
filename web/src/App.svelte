<script lang="ts">
    import { CONFIG, ID_INFO, IS_BROWSER } from './stores/stores';
    import { InitialiseListen } from '@utils/listeners';
    import Visibility from '@providers/Visibility.svelte';
    import Card from '@components/Card.svelte';

    CONFIG.set({
        fallbackResourceName: 'bl_idcard',
        allowEscapeKey: true,
    });

    InitialiseListen();
</script>

{#if $ID_INFO}
    <main>
        <Card />
    </main>
{/if}

{#if $IS_BROWSER}
    {#await import('./providers/Debug.svelte') then { default: Debug }}
        <Debug />
    {/await}
{/if}

<style>
    main {
        position: absolute;
        left: 0;
        top: 0;
        z-index: 100;
        user-select: none;
        box-sizing: border-box;
        padding: 0;
        margin: 0;
        height: 100vh;
        width: 100vw;
    }
</style>
