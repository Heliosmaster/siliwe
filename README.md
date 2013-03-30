## Siliwe
**Si**mple **Li**bra **We**bsite

This small and **very simple** Sinatra web application is aimed at providing a basic functionality somewhat complementary to the Android app [Libra](https://play.google.com/store/apps/details?id=net.cachapa.libra) developed by [Daniel Cachapa](http://cachapa.net/).

###Features
* Authentication provided via [Google OAuth2 API](https://developers.google.com/accounts/docs/OAuth2) (as Siliwe is supposed to go alongside an android app, it's presumed one has a Google Account to use)
* Trend computation (similar to the Libra app) following the [Hacker's Diet](http://www.fourmilab.ch/hackdiet/e4/pencilpaper.html)
* Weight and trend graphs (using [Highstock](http://www.highcharts.com/products/highstock)). Apparently, stock charts work quite well with measurements over (ideally long) time, like weights.

### This code sucks!
Yes, I am fully aware of it. This is my first real try.

You are most definitely welcome to point out all the obvious errors, bad practices and all the other things that make you irk, either using GitHub issues or directly commenting the code.

### License
[MIT license](LICENSE).