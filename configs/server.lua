return {
    offerTime = 10000,

    tolerance = {
        view = 35.0,
        flash = 3.0,
        give = 2.5,
        handover = 3.0,
        keep = 10.0,
    },

    photos = {
        provider = 'mysql',
        retakeOnIssue = false,
        cleanup = {
            intervalHours = 24,
            graceMinutes = 60,
        },
    },
}
