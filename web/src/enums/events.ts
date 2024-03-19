export enum Receive {
    cardData = 'idcard:data',
    config = 'idcard:config',
    requestBaseUrl = 'idcard:requestBaseUrl',
}

export enum Send {
    resolveBaseUrl = 'idcard:resolveBaseUrl',
    close = 'idcard:close',
    loaded = 'idcard:loaded',
}