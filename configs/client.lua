return {
    viewDistance = 25.0,
    giveDistance = 2.0,

    poses = {
        hold = {
            dict = 'cellphone@',
            clip = 'cellphone_text_read_base',
            bone = 28422,
            offset = vec3(0.0, 0.0, 0.025),
            rotation = vec3(0.0, 90.0, 0.0),
        },
        flash = {
            dict = 'bl_idcard_anim',
            clip = 'show',
            bone = 28422,
            offset = vec3(0.0, 0.0, 0.025),
            rotation = vec3(0.0, 90.0, 0.0),
        },
        car = {
            dict = 'cellphone@in_car@ds',
            clip = 'cellphone_text_read_base',
            bone = 28422,
            offset = vec3(0.0, -0.005, 0.045),
            rotation = vec3(0.0, 90.0, 0.0),
        },
        windowShow = {
            dict = 'bl_idcard_anim',
            clip = 'car',
            bone = 28422,
            offset = vec3(0.0, -0.01, 0.025),
            rotation = vec3(-10.0, 50.0, -20.0),
        },
    },
}
