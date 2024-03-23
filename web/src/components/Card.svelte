<script lang="ts">
    import { ID_INFO, ID_TYPE } from '@stores/stores';
    import Pattern from './svgs/Pattern.svelte';
    import PfpOverlay from './svgs/PfpOverlay.svelte';
    import Stamp from './svgs/Stamp.svelte';

    let { id, firstName, lastName, dob, sex, imageURL } = $ID_INFO;

    let { title, label, stamp, profileStamp, signature } = $ID_TYPE;
</script>

<div
    class="aspect-ratio h-[20vh] bg absolute top-1/4 right-1/4 rounded-[2vh] overflow-hidden grid place-items-center py-[0vh]"
>
    <Pattern />

    <div class="w-full h-full flex flex-col z-10">
        <span class="flex flex-col items-center justify-between gap-0">
            <h1
                class="uppercase text-txt-secondary font-bold tracking-[0.25vh] text-[2.5vh] grid place-items-center whitespace-nowrap"
            >
                {title}
                <h1
                    class="absolute text-txt-secondary text brightness-75 -z-10 whitespace-nowrap"
                >
                    {title}
                </h1>
            </h1>
            <h1
                class="uppercase txt-primary opacity-80 font-bold text-[1.5vh] whitespace-nowrap leading-[1vh]"
            >
                {label}
            </h1>
        </span>

        <!-- <div class="w-full h-[0.2vh] bg-black/20" /> -->
        <PfpOverlay />
        <div
            class="grid place-items-center w-[10vh] h-[10vh] left-[0.5vw] rounded-full overflow-hidden absolute top-1/2 -translate-y-1/2"
        >

            <div
                style="background-image: url({imageURL});"
                class="w-full h-full bg-center bg-contain bg-no-repeat grid place-items-center z-10"
            />

            <div
                style="background-image: url({imageURL});"
                class="w-1/2 h-1/2 rounded-full bg-center bg-contain bg-no-repeat grid place-items-center z-0 absolute blur-[1vh]"
            />
        </div>

        <div
            class="flex flex-row w-[18vh] h-full items-start justify-between uppercase roboto-condensed-bold overflow-visible absolute right-[2vh] top-[5.5vh]"
        >
            <div class="flex flex-col items-start justify-center gap-[1vh]">
                <span class="flex flex-col gap-0 items-start justify-center">
                    <h1 class="text-[1.2vh] text-txt-primary opacity-80">ID</h1>
                    <h1 class="text-[1.5vh] text-txt-primary leading-[1vh]">
                        {id}
                    </h1>
                </span>

                <span class="flex flex-col gap-0 items-start justify-center">
                    <h1 class="text-[1.2vh] text-txt-primary opacity-80">
                        LASTNAME
                    </h1>
                    <h1 class="text-[1.75vh] text-txt-primary leading-[1vh]">
                        {lastName}
                    </h1>
                </span>

                <span class="flex flex-col gap-0 items-start justify-center">
                    <h1 class="text-[1.2vh] text-txt-primary opacity-80">
                        FIRSTNAME
                    </h1>
                    <h1 class="text-[1.75vh] text-txt-primary leading-[1vh]">
                        {firstName}
                    </h1>
                </span>
            </div>

            <div class="flex flex-col items-start justify-center gap-[1vh]">

                <span class="flex flex-col gap-0 items-start justify-center">
                    <h1 class="text-[1.2vh] text-txt-primary opacity-80">
                        EXP
                    </h1>
                    <h1 class="text-[1.5vh] text-txt-primary leading-[1vh]">
                        12/12/2030
                    </h1>
                </span>

                <span class="flex flex-col gap-0 items-start justify-center">
                    <h1 class="text-[1.2vh] text-txt-primary opacity-80">DOB</h1>
                    <h1 class="text-[1.5vh] text-txt-primary leading-[1vh]">
                        {dob}
                    </h1>
                </span>

                <span class="flex flex-col gap-0 items-start justify-center">
                    <h1 class="text-[1.2vh] text-txt-primary opacity-80">
                        SEX
                    </h1>
                    <h1 class="text-[1.5vh] text-txt-primary leading-[1vh]">
                        {sex.split('')[0]}
                    </h1>
                </span>


            </div>
        </div>

        {#if profileStamp}
            <div
                class="absolute grid place-items-center w-[4vh] h-[4vh] right-[0.75vh] bottom-[0.75vh] rounded-full overflow-hidden"
            >
                <img
                    src={imageURL}
                    class="w-full h-full object-cover z-10 absolute opacity-60 hue-rotate-[210deg]"
                    alt={firstName + lastName}
                />

                <img
                    src="./profileGradient.png"
                    class="w-full h-full object-cover z-0 absolute"
                    alt={firstName + lastName}
                />
            </div>
        {/if}

        {#if stamp}
            <div
                class="absolute w-[12.5vh] h-[12.5vh] right-[5vh] bottom-[2vh]"
            >
                <Stamp />
            </div>
        {/if}

        {#if signature}
            <h1
                class="text-[4vh] left-[1vh] signature text-txt-primary underline decoration-[0.135vh] underline-offset-[-0.5vh] absolute translate-y-[20%] bottom-[0.5vh] opacity-80 z-50"
            >
                {firstName}
                {lastName}
            </h1>
        {/if}
    </div>
</div>

<style>
    .aspect-ratio {
        aspect-ratio: 1.59259259259;
    }

    .bg {
        background: var(--bg);
        background: linear-gradient(
            120deg,
            var(--bg) 0%,
            var(--bg-secondary) 100%
        );
    }

    .text {
        text-shadow:
            0.1vh 0.1vh 0.1vh var(--title),
            0.2vh 0.2vh 0.1vh var(--title),
            0.15vh 0.15vh 0.1vh var(--title);
    }
</style>
