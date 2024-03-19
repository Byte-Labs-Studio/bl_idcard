local Events = {}

Events.Receive = {
    loaded = 'idcard:loaded',
    resolveBaseUrl = 'idcard:resolveBaseUrl',
}

Events.Send = {
    requestBaseUrl = 'idcard:requestBaseUrl',
    cardData = 'idcard:data',
    config = 'idcard:config',
}

return Events