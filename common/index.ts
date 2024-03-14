import { cache } from '@overextended/ox_lib/shared';
import { ResourceContext } from 'config';

console.info = (...args: any[]) => console.log(`^3${args.join('\t')}^0`);

DEV: console.info(`Resource ${cache.resource}/dist/${ResourceContext}.js is running in development mode!`);
