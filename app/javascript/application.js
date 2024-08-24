// Entry point for the build script in your package.json

import './src/jquery.js'

import './vendor/typeahead.js';
import '@fancyapps/fancybox';
import 'lite-youtube-embed/src/lite-yt-embed.js';

import * as bootstrap from "bootstrap"


// UJS is necessary to get link_to -> delete working (in the list pages)
// it used to be included by default, prior to Rails 7, and is now deprecated
import Rails from '@rails/ujs';
Rails.start();
