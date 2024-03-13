<script lang="ts">
    import { ID_INFO } from '@stores/stores';
    import Pattern from './svgs/Pattern.svelte';
    import PfpOverlay from './svgs/PfpOverlay.svelte';
    import Stamp from './svgs/Stamp.svelte';
    import PfpStamp from './svgs/PfpStamp.svelte';

    // id: string;
    // firstName: string;
    // lastName: string;
    // dob: string;
    // sex: string;

    let { id, firstName, lastName, dob, sex } = $ID_INFO;
</script>

<div
    class="aspect-ratio h-[20vh] bg absolute top-1/4 right-1/4 rounded-[2vh] overflow-hidden grid place-items-center px-[1vh] py-[0.5vh]"
>
    <Pattern />

    <div class="w-full h-full flex flex-col z-10">
        <span class="flex flex-row items-center justify-between">
            <h1 class="uppercase text-[#F97C81] font-bold text-[2.5vh] text">
                San Andreas
            </h1>
            <h1
                class="uppercase text-[#4D4F83] font-bold text-[1.5vh] opacity-80"
            >
                ID Card
            </h1>
        </span>

        <div class="w-full h-[0.2vh] bg-black/20" />

        <div class="flex flex-row items-center justify-between w-full h-fit">
            <div
                class="grid place-items-center overflow-visible w-[10vh] h-[10vh] rounded-full"
            >
                <PfpOverlay />
                <div
                    style="background-image: url({'https://alp1x.github.io/um-idcard-maker/img/player.43f34e32.png'});"
                    class="w-full h-full bg-center bg-contain bg-no-repeat grid place-items-center z-10"
                />
                <div
                    style="background-image: url({'https://alp1x.github.io/um-idcard-maker/img/player.43f34e32.png'});"
                    class="w-[55%] h-[55%] rounded-full bg-center bg-contain bg-no-repeat grid place-items-center z-0 absolute blur-[1vh]"
                />
            </div>
            <div
                class="flex flex-row w-[18vh] pr-[1vh] pt-[1vh] h-full items-start justify-between uppercase roboto-condensed-bold overflow-visible"
            >
                <div class="flex flex-col items-start justify-center gap-[1vh]  overflow-visible">
                    <div class="flex flex-col items-start justify-center gap-0">
                        <span
                            class="flex flex-row gap-[0.5vh] items-center justify-center"
                        >
                            <h1 class="text-[1vh] text-secondary opacity-80">
                                ID
                            </h1>
                            <h1 class="text-[1.5vh] text-primary">
                                {id}
                            </h1>
                        </span>

                        <span
                            class="flex flex-row gap-[0.5vh] items-center justify-center"
                        >
                            <h1 class="text-[1vh] text-secondary opacity-80">
                                LN
                            </h1>
                            <h1 class="text-[1.5vh] text-primary">
                                {lastName}
                            </h1>
                        </span>

                        <span
                            class="flex flex-row gap-[0.5vh] items-center justify-center"
                        >
                            <h1 class="text-[1vh] text-secondary opacity-80">
                                FN
                            </h1>
                            <h1 class="text-[1.5vh] text-primary">
                                {firstName}
                            </h1>
                        </span>
                    </div>

                    <div class="flex flex-col items-start justify-center">
                        <span
                            class="flex flex-row gap-[0.5vh] items-center justify-center"
                        >
                            <h1 class="text-[1vh] text-secondary opacity-80">
                                DOB
                            </h1>
                            <h1 class="text-[1.5vh] text-primary">
                                {dob}
                            </h1>
                        </span>

                        <span
                            class="flex flex-row gap-[0.5vh] items-center justify-center"
                        >
                            <h1 class="text-[1vh] text-secondary opacity-80">
                                SEX
                            </h1>
                            <h1 class="text-[1.5vh] text-primary">
                                {sex}
                            </h1>
                        </span>
                    </div>
                </div>

                <span
                    class="flex flex-row gap-[0.5vh] items-center justify-center"
                >
                    <h1 class="text-[1vh] text-secondary opacity-80">EXP</h1>
                    <h1 class="text-[1.5vh] text-primary">12/12/2030</h1>
                </span>
            </div>
        </div>

        <div class="absolute grid place-items-center w-[5vh] h-[5vh] right-[1.5vh] bottom-[1.5vh] rounded-full overflow-hidden">
            <img src="./profileGradient.png" class="w-full h-full object-cover z-0 opacity-50 absolute" alt={firstName + lastName}/>
            <img src="https://alp1x.github.io/um-idcard-maker/img/player.43f34e32.png" class="w-11/12 h-11/12 object-cover z-10 absolute  opacity-50 hue-rotate-[210deg]" alt={firstName + lastName}/>
        </div>


        <div class="absolute opacity-10 w-[10vh] h-[10vh] right-[2vh] bottom-[2vh]">
            <Stamp />
        </div>



        <h1
            class=" capitalize text-[3vh] mr-dafoe-regular text-black underline pl-[1vh] decoration-[0.18vh] absolute bottom-0"
        >
            {firstName}
            {lastName}
        </h1>
    </div>
</div>

<style>
    .aspect-ratio {
        aspect-ratio: 1.59259259259;
    }

    .bg {
        background: rgb(241, 230, 219);
        background: linear-gradient(
            90deg,
            rgba(241, 230, 219, 1) 0%,
            rgba(211, 247, 255, 1) 100%
        );
    }

    .text {
        text-shadow:
            0.1vh 0.1vh 0.1vh #b15558,
            0.2vh 0.2vh 0.1vh #b15558,
            0.3vh 0.3vh 0.1vh #b15558;
    }
</style>
