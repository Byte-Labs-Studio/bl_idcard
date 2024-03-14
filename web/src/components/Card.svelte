<script lang="ts">
    import { ID_INFO, ID_TYPE } from '@stores/stores';
    import Pattern from './svgs/Pattern.svelte';
    import PfpOverlay from './svgs/PfpOverlay.svelte';
    import Stamp from './svgs/Stamp.svelte';

    let { id, firstName, lastName, dob, sex, imageURL } = $ID_INFO;

    let { title, label, stamp, profileStamp, signature } = $ID_TYPE;
</script>

<div
    class="aspect-ratio h-[20vh] bg absolute top-1/4 right-1/4 rounded-[2vh] overflow-hidden grid place-items-center px-[1vh] py-[0.5vh]"
>
    <Pattern />

    <div class="w-full h-full flex flex-col z-10">
        <span class="flex flex-row items-center justify-between">
            <h1
                class="uppercase text-txt-secondary font-bold text-[2.5vh] grid place-items-center"
            >
                {title}
                <h1
                    class="absolute text-txt-secondary text brightness-75 -z-10"
                >
                    {title}
                </h1>
            </h1>
            <h1 class="uppercase txt-primary opacity-80 font-bold text-[1.5vh]">
                {label}
            </h1>
        </span>

        <div class="w-full h-[0.2vh] bg-black/20" />

        <div class="flex flex-row items-center justify-between w-full h-fit">
            <div
                class="grid place-items-center overflow-visible w-[10vh] h-[10vh] rounded-full"
            >
                <PfpOverlay />
                <div
                    style="background-image: url({imageURL});"
                    class="w-full h-full bg-center bg-contain bg-no-repeat grid place-items-center z-10"
                />
                <div
                    style="background-image: url({imageURL});"
                    class="w-[55%] h-[55%] rounded-full bg-center bg-contain bg-no-repeat grid place-items-center z-0 absolute blur-[1vh]"
                />
            </div>
            <div
                class="flex flex-row w-[18vh] pr-[1vh] pt-[1vh] h-full items-start justify-between uppercase roboto-condensed-bold overflow-visible"
            >
                <div
                    class="flex flex-col items-start justify-center gap-[1vh] overflow-visible"
                >
                    <div class="flex flex-col items-start justify-center gap-0">
                        <span
                            class="flex flex-row gap-[0.5vh] items-center justify-center"
                        >
                            <h1 class="text-[1vh] text-txt-primary opacity-80">
                                ID
                            </h1>
                            <h1 class="text-[1.5vh] text-txt-primary">
                                {id}
                            </h1>
                        </span>

                        <span
                            class="flex flex-row gap-[0.5vh] items-center justify-center"
                        >
                            <h1 class="text-[1vh] text-txt-primary opacity-80">
                                LN
                            </h1>
                            <h1 class="text-[1.5vh] text-txt-primary">
                                {lastName}
                            </h1>
                        </span>

                        <span
                            class="flex flex-row gap-[0.5vh] items-center justify-center"
                        >
                            <h1 class="text-[1vh] text-txt-primary opacity-80">
                                FN
                            </h1>
                            <h1 class="text-[1.5vh] text-txt-primary">
                                {firstName}
                            </h1>
                        </span>
                    </div>

                    <div class="flex flex-col items-start justify-center">
                        <span
                            class="flex flex-row gap-[0.5vh] items-center justify-center"
                        >
                            <h1 class="text-[1vh] text-txt-primary opacity-80">
                                DOB
                            </h1>
                            <h1 class="text-[1.5vh] text-txt-primary">
                                {dob}
                            </h1>
                        </span>

                        <span
                            class="flex flex-row gap-[0.5vh] items-center justify-center"
                        >
                            <h1 class="text-[1vh] text-txt-primary opacity-80">
                                SEX
                            </h1>
                            <h1 class="text-[1.5vh] text-txt-primary">
                                {sex}
                            </h1>
                        </span>
                    </div>
                </div>

                <span
                    class="flex flex-row gap-[0.5vh] items-center justify-center"
                >
                    <h1 class="text-[1vh] text-txt-primary opacity-80">EXP</h1>
                    <h1 class="text-[1.5vh] text-txt-primary">12/12/2030</h1>
                </span>
            </div>
        </div>

        {#if profileStamp}
            <div
                class="absolute grid place-items-center w-[5vh] h-[5vh] right-[1.5vh] bottom-[1.5vh] rounded-full overflow-hidden"
            >
                <img
                    src="./profileGradient.png"
                    class="w-full h-full object-cover z-0 opacity-50 absolute"
                    alt={firstName + lastName}
                />
                <img
                    src={imageURL}
                    class="w-11/12 h-11/12 object-cover z-10 absolute opacity-50 hue-rotate-[210deg]"
                    alt={firstName + lastName}
                />
            </div>
        {/if}

        {#if stamp}
            <div
                class="absolute opacity-10 w-[10vh] h-[10vh] right-[2vh] bottom-[2vh]"
            >
                <Stamp />
            </div>
        {/if}

        {#if signature}
            <h1
                class="text-[3vh] signature text-black underline pl-[1vh] decoration-[0.18vh] underline-offset-[-0.5vh] absolute bottom-0"
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
            90deg,
            var(--bg) 0%,
            var(--bg-secondary) 100%
        );
    }

    .text {
        text-shadow:
            0.1vh 0.1vh 0.1vh var(--title),
            0.2vh 0.2vh 0.1vh var(--title),
            0.3vh 0.3vh 0.1vh var(--title);
    }
</style>
