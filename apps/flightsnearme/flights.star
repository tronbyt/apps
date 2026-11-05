load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

# Bundled full airline logos; see THIRD_PARTY_NOTICES.md.
AIRLINE_LOGOS = {"AAL": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAtElEQVR4nGP88OHDfwYSABOIELrFBMZEa7D/+JqB+f4TBtEdTwlqYIQ5SXLGSYb//yGue5Fpgd8GEHieYc7A8uApGBNlAwz8/POf4e3HLwwv3r1j+PnzB4OljjoDMsDw6d9/IGMYGB4Ge2MoZsBmAwh8s9Fn+PT3P8PHv/8Z1E9dxm8DCIBMYISyz5roEtbAfeQixHqotnMJMfg1gID48UsM/xn+gzV9uniB4d+vX7j9gA8AAHvZTTzBZWhSAAAAAElFTkSuQmCC", "AAR": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAnElEQVR4nGNgIAD+vf/w/52Rzf93htb/f1+68p8Rl8J35g7/GX79xhBH0fC1o+//z5VrcVvHygrRALIOlxomcTGGfy9fgdlC548yMuFSzLduGVjBP6hiuAEMTExwDldVCVgRCLMoyjP+uXsfbhhHdDimH9ABsu1C54+C1SKMJxLg1PBz11646Wx+XnBx3PGAxTnUdRKTiDCG6SABAKQzPA6sieApAAAAAElFTkSuQmCC", "ALK": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAe0lEQVR4nGNgGFTgLofcf6IV/zh1njjFH2cv+X+HQZoIxUul/t9hkAHjbwti8WtgXy77/+GP51ANkv8/pjPANbCgK17/aNv/Z99fMPzmMAXzVRieM34SEPvPwPAK02S2JeJgk2BOAfshB2E6BngWEAf24JeNO4gPPqoDALHkOmRUybmYAAAAAElFTkSuQmCC", "AXB": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAlklEQVR4nM2ROwrCUBBF7xO34Ta0cBXiDnQRLknICmyyALFW0E7F2KUV8j5H8l4iBtKkES/M584XZgwBNACjIcW/aRhHbRrGl9+Cng1kufQopWcpvSopIFkv7Y9pgJHY7qRrIQG42ZoOzjcoStx0RbjcsZMllZnHlOqzfuAb4pJ1i003Xr+gbQhZTjicErE+JvvE/N/j3iiDohL49EHJAAAAAElFTkSuQmCC", "BAW": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAABUklEQVR4nEWRvy5EURDGf3Pu2fWvkdiIREF0/hRkKxovoBOhwCNQaPWi8gg0Kl6AXiIRxUYlgk5ECAmxYe0ZmTmXPbknmTN3Zr5vvk96ppdVJICIX4tFBMXi/LYjIddEUFQTQv4ByYuRgKrmYhFSSt4ULTlcKFPxh4mizWTRpl78EK3fG8S/xWaNu1QhWvKhLTykyCnRKfQFqAZoUdAkYPhjXd1Iq5UR/Bgt5574SAFRm6xUBkYYHJ0jvr+htyeGYJwdn2bj2Ht7Z1Y893l5SF99lceXex5dGDKCiGvCeeOa59f3vCglMupRqZuNVjSlf0WWNnepxMDT2T7za9sc7W358rkmYdrlKZqoxsjBzgZfX9/UZte5uLphqNZfDrMmRSrjC25cx6wcZxOzH9mLbFwwgh1KdstY1c0y5D8Glovusk0vnfRiyWu72ylBCJ4yyX8BrRupQUE98mUAAAAASUVORK5CYII=", "CPA": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAA+0lEQVR4nGNkSAj8LyckwvDo7RsGhv//GRgYGRgY/oMwiICC/wg2EwMjI4Ortj5EISOIgAIcbCYQ8f33L4YgI3OEArhCTDYTiFh28giDuqQMwha4iZhsJpgBFsqqDPOSsmGORjL9Pwob7AcQyFo8myHR1plhb2kD1H6QiQwYbIgNjIwMTz++BzOdtPQY/i9Yh9N5jAzJIf+Rg+3/3DUo/n758QODRH4SPGjhfoAHRlIwCl+cXwBhI1wDstWMjAy6dYUoBjAmBsHVsIAZMCcxMjL8n7OagS0tnIExOYSB4R80hEBqoGyoDQwMqzKKIMzkEIbff/9ij7j/DAwAPuxC/FIKxaQAAAAASUVORK5CYII=", "DAL": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAABA0lEQVR4nGVRsW7CQAx9PqiKVLGUAuqWpUKFoZ/DxIy68ReMzJn5AsZurMwgoOqStQlMCAmEiCuf78KFWkrunf1sP/sIHwMGDEBQIyM/h+kflijAOcCsATnlDgZy72fFYJgyUcnt60UxBcVIsUtwDjkBLHZbxL9LvZLXilCSrw6MjmkRfr6ebx1cd+Or+k6jY1YkjHfftxnkYy5LSrIN7i1OV46s8owOw0iyrSWsqjVEzXcMW12cqGJ9EylkpQVDzx7riF46mD882U5xusa0/ophs4uDqRayCb0+S6tk/1OS8hXgHITPVs/K1lTOETXeghWSYr9Wi+XhSBLCLd2bEL1f8R/enYdM6Xcb8AAAAABJRU5ErkJggg==", "ETD": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAABAElEQVR4nJVRPUsDQRB9s1pokUoRbAT/SBAkCDai/8EfYWulf8JKyyCkiKQIiVaKXSBgpdhoIXeXFXO5xLt9shNz5PAD7sHuzDLz5jFvhSRRAqZM8y+EqdhM1N906d+EsLGJ9+4B0uAOZAYBMH48K850znF2PILLFY3D/ilHTxeaz/fAdnc4jyxNOOwd0bmU2Tii7dTy2qCzTWOW1hHU15B7lcVwSQhgAbJYQaXaRNw7RlhfhVne0AW9Ju3NHidvt4yuthi1qhy0d7Vkr/f5afu5inzHqSdidFEVIyHiX0WoS74gYuDiF3zcHyopeTjB5LWF5Pm8QFCFH2P+Qemf/gLlf8Rk1bcQhgAAAABJRU5ErkJggg==", "EZY": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAA00lEQVR4nF1RMQoCQQycrAe29oIfsDoLLS2tFSux1MaHWNsJPsDHWMo9QawtRYTIZpNcvIO9ZJPZySSh7x4MAJR/6mSfGSAPwvMJmpRXcmnB2dpnfspWmPSRHwWwPVKC5NTUmqDkvxIBVWSRZAR3KpH1QPUKqPoFPD8AkzVougEPhiU22yJdWHzpgZ8NqvMbvdMLaXkEjWrw7QoaL4q8x90V0GcXxhr6cBk2Zo1LD5LMgTjeDLTpKYNLig0LyChjOXWTTSIuyep3F9dWCEnfeudu8n5mBlv5YpkE2gAAAABJRU5ErkJggg==", "FDB": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAA4klEQVR4nF2QTQ4BQRCFX/eIpdlxAbFla0PEKeydQsIN2Iu1a1hxEHYTm+lIxgYlVf1X9KTTX/er6Xr9zGM3ImMMwJMIwuAZ2Y/IlkUikmJfyIOZj/yq2ZIS+fvwKuwH/bFNu2hJcRCQWSzxjcCl6Ydbcnu5nTSLJaB6l1jdF5jeNmKLlUM9w+S6xtGNUb06eFJb3iaWeoVLLaOlZXmS/b6eo1s4nJuBqMZth9IrRZuy0tFmbrE3I9GK09SJa6SMBcUqJV/PP/uUftOLbH1q/NCQYHh0PvdCZGVJ2Yme47my9AUQN5WJkoSrpwAAAABJRU5ErkJggg==", "FIN": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAU0lEQVR4nGP8////fwYSABMpioeqBhbeLIav338zfP/5G8xnBIWSsWUrw5/f/zAUXzr/iKGixodBU12CIS7KHKEBV8iChJmYGFHEwBqo6gf6awAABmgkUrL8HCcAAAAASUVORK5CYII=", "IBE": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAq0lEQVR4nGN8//79fwYSABMpionSwHojhYHzkjQD9z1JBob/PxlY8CrepsDAxPWP4T83I8N39YMMDIzsuDUwL1Vn+B1yhoGBXQRFHLuGnx8ZfigvY/hkEgwXEr58ELeGtyZ+OJ3Jgsy5o2vNwM7AxMDJwMTAiCQOMx0E4KF0QdeS4Q8DA8Mfhv9gDAOC+9Zh2nBE14yBg4EJrJAZqomVl5dB+NhWDCcx0jymAVwyLn51zO6VAAAAAElFTkSuQmCC", "JAL": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAABLklEQVR4nHWOMUvDUBSFz2tK7dBiU62FFAfR1UF0E3EvSjfRv+HmPxARCnXS3cUf4OZSRMFRHHUxJMbSRiVBmprkSB/Na0P1Lu/de8757gUmKnI/2NnYZNJ3t+sMTUv1qbJR/lvAUJvjlNk/O6ffumBnfYtWrkgbJSbGoH1HCwX+Txia7h/4fXml5kNo5HSIt5KhSEl9HR6xt7OXmtmYpY0i4Z006ays0j9tTdDSgP5Nm95xk27jgEKmkJOCgZ54X15j9PIq/9OAEKJbb3BwfatoojgDesGoiwFklJbf34WkpE8goGWQqeiIHRfaYg2RaUml6j4n8bF/wXyCtmRAVAogAlTNRwklBtDKuhjfmdPJwQ8EsiNA8oagiFGjL70qoIL5eaI/2piNYISfKc8vLyiSBUYw1kwAAAAASUVORK5CYII=", "JBU": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAV0lEQVR4nGPkMIj9z0ACYCJF8QBq6CiKJKxh6/QyhiBXMzB7w97TYPrQ4now7WGjz/D9/CIwmwWmwTuzC27KiYt3GPJiPOD89ZOLGTgN48BsxuEarPgAAJwNFWzTZzQiAAAAAElFTkSuQmCC", "LAN": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAqElEQVR4nGP8////fwYSABMpinFqeCfow/DvzUcGBmyW/0cCfy7e+f+Gww3M/hTZ9P+tRND/TWuuISv5z4jsh//vPzMwCvIyfJIIYJB+ZcfA9v8vw9v/pbhtAAFt0Yn/f/36+//1m6//pRg6/y9fdglFHkMDCMizdP1PiVj3/+/ffxhyGJ4GOfDtn+8Ma1ZcYWBiYsTwM4ofiAFYg7WxfB9ODdSxAR8AAHbKqRUaJxSfAAAAAElFTkSuQmCC", "MAS": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAABG0lEQVR4nJVRLU8EMRB90+4CF+4UDgUKAycg4QwKkBiSUygElgR+CRKLIBB+AIYPhUESMCjcbjCXkHCI3fY6ZGazXTanmKbtdPrevOmU8jxn/MOS2hEWcZurMchC0wQIuDvfHK0FVjcRjIF5uoskExG9rnJYlvEP4DwQAsh7hI2tKmGL8D0GnAOvDSqF3b2mtjSNrhI0q+z9AciYKttopHGu78Sv35AmFp3OLJb7ByhKj9vPL+yvDGNWYsYLV7sq+ElAWZR6+XFzguv7V+1OPd8vj2GsAREhEamd0wutYnGhB+cDrh7eVFVse30JhZsoOLb18ewwygdmBQvg+fwIczNJBGt5WZZxaP0Xg2SQtL4Bxo+ToG3Fp0F/7RfuGmyreNBHrAAAAABJRU5ErkJggg==", "MSR": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAABKElEQVR4nGNgQAJb95//z6kZ959BKeo/g3L0fwbFqP8FLYv/M6CDK7ce/2dQiwUrXLPj1P+37z//L2hd8j+hYMr/89cegDWkV81G0ggyjYGBQcIsE6xxzqr9/wuaF4HFZizf+3/TnrOotly88QiskFcn6X/T5PX/8xoX/mdRiYEr0nYtQWh4++ELWPHmvef+MylF/bcIrP3PoBLz/8Xrj2BF8SXTUU3vmr0FIqAa8z8idxLYowdPXQcb4pfSg+nhOw9f/Fe1L/jPoBL9/9aDF2CFh8/chAQCTqAGlVSL/b9u1ymwkzi0ErBqYAKTP3/DBYLczBgZmBgZ7u3vx2o2RMPDFYx67mX/Gf4jDJUSF2TE7SQYkA2DOw2XEogNMPB4FcTUP39xmgkAmG+SrqnuxEkAAAAASUVORK5CYII=", "OMA": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAABP0lEQVR4nJ1Qu0oDQRQ9u87sZnbzmKARjIkkmEchPrBSsBJJbSF+gP/jH9iL4CdYiqSKlYmFYOPGJhJBk5lN3B3ZCRuLtdFTDIfhnse9wB9hRM9Dt6copejcnEOFCszJwmYuUnYaLM1h2S4mcoy91plhRgJCCCzLAiEWtvePQa0UmJsHL5TBnBxMwwRNObOE27u24pyDkgWMhcBT+wJOmsO2XTA3hwxfRr5QQbm2q9uQIAhgUYLP0QiTyRRLzROUFhW853udGHxN58Na4Ps+BoM3OA6DEALS99F5/EBzpYidg9P5YAyzdXRoCCkxHL4jm8lACIkwDNHz9HoJ6N/1ahVjIeH1X2GaP6YvXl/9KqhU1gxdR0qdEF0tQmm1mKwUk63NDUQHiLlSCfPZ0jFp1GvG5dW1CkOFZqOecP43vgF/hWfgB/dCTQAAAABJRU5ErkJggg==", "PAL": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAzklEQVR4nGP89+/ffwYSAAsjIyPDv3//iFLMxMTEwIRPASMjJocJl+I//5kYGBkh0oxMIDYeDdv3nWNgl05m+PvnL8O/ly8Z3mlqMPz//Ru7BkmjXAajfw4McuJfGN4ryDF8dHKEOIeZGeJpZMXMApEMDJw8DGIC3xjOfrrMwMjLC/Mtwiv///8HB+uMFm2GF+85GOx0XjHo9/IwMCAH9s9fDIK3boNDCazh79+/qIGBLWYYGcEawE6ChQBCElfY4QlWXIAF5AWQVcQAkFoAgiU8LQ+AdigAAAAASUVORK5CYII=", "QFA": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAwUlEQVR4nGP8////fwYSABMpisnSwAJjvNOWY2Dk4mFg+POPQfD8Ddw6/kPBvw/v///49+//ewuj/28kJf7jAgzInLda6v/Pzpj5/+fho/8fyqsS1vDRP/D/MxkFMPu6tPL/UzxCGBoYUYL171+GO/LqDN8Y/jP8ZPjH8OvPXwYmNjYGy4e3GRgYGcFKUDUwMDDkFBQyGBsZMsRGRTGsXrsWpITh8+fPDGkpydg1gMC/f/8YmJggIY7MxqkBHyA54gDvNbNprB8PeQAAAABJRU5ErkJggg==", "QTR": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAABWElEQVR4nG1RPUsDQRB9c7dXagQLKxsDGo0J6VJa2GswhBgwWgjqLxCs/A8W2qRQENTOPyBiJVgJqWxSaAoNEb3Er+QutzKzd+YKZ1h2dufzzaOKymhCpABRaGtjWzDCfxYfDSDQGkYBzTYf0gh0gCD8X9gqim3Jk4ZJf8kcBaD2dScFpvIZuZU4CKjsbqPf6+G7+4nmQwPPjSe4rTfYSkmH2uY+LAKoZKf15HQSnVYbH25XcBw1r5GYGEfVyRlcMYyKs73eD/xgIKOceXUZxX15lcpDMS/BsFheQmGninOvjo1EXhzc4dS7x/rB3nAhvMEVe06PjI3iuH0rgWUng4uwSyRrTs5UN2vV6L53UFRplNS8bCmSm5NLVFQ2rM9DaVDBTglxydkZ+H4fft/HwPNx+HiFVScbgo4BX7ZTUsCKGI6cRMwiLOJBDGaO+Zc4YTccjdmOx/wC51mvxwLtBYYAAAAASUVORK5CYII=", "RJA": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAABMUlEQVR4nGNgGBBw9diq//dvnP2PTY4FmbNtVvb/d89vM4ip2DI8fPiQYUmD238hWV0Gr+ReRpgaMGNxo9t/JiYWBiZGRobImq2MS5u9/jMxMjBE1mxjXNbi/Z/h/z8GdesoBmOnWEamNb0R//n1MxjUTHwYfv+FmMLFJ8zwk00azP737w/DfxlPhrunNzAs6Yj4z/Tr+2cGv4AgRlPPLEYWZoiGrx9fMzB9fwJmMzGxMEQn5jFy8YkwMP/5BFGwqMET7MHlrV7/z54+/v/58+f/r167+f/B9eP/1/VFgOWWNPuAabhnljV7/f/3/x8DIyMzAxMTyNn/Gf4zMDL8+/8f7Lfo2m1gtYhQkvNjYGFignNhJoFc+e8fyHPbUIOVnY2Z4dOnz1jjhZmNg5joww4A7DJshq+IFqAAAAAASUVORK5CYII=", "SAS": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAe0lEQVR4nGNk9lv0n4EEwESKYjprqAjRYfizMRaMQQBE9yabwNlXp/qhamiJNWTYdf4ZA4v/Yrim4rln4CZrZ29C1fD//38GN0MpBiYmRobONVfwO+nPxlgGRkZGBrbAJQz//v1nmL79Jljy8hQ/sNzvP//gGhiHQTwAADJXLhYAEsLkAAAAAElFTkSuQmCC", "SIA": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAA1ElEQVR4nJWQPw8BQRDF3y4fwJfQ+F+qVHokaoVodCrfRKmiUTmJSkKhkIhGQSMRBaFQSxSz9+Rc7oKwidfsZHZ+M3kP+JBZtgiL9GeDlynMrGKFQskox9fXesHsugQJcVKEKxAnw7+2y48rOqwokFGWKl5/DutC/yukgyJa3ihAAbeTz+97dg/woNJa8TyBznegYgmArh3wV7twFw3gdkSkOIY5DH6bN6t2+GnmNQYezKL5HeL9SplVKcMUZZj00/JifpEKCnHSz/zfpDSilW0447UeWNFo6iIbeu8AAAAASUVORK5CYII=", "THA": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAABU0lEQVR4nI1S3SuDURx+zstsRMrVlGxxw6KVUZTX5sKEcrF2YySUv0GRSyUp8R9YLlfaDeJuKbtbPuZzTSvuyIW9874bHjmyZfl6rn7n9PR8nN8B/sDTuYP6ZSs/z6W/kVenXex3Nsn5LppgjSsJpZiUewjyNXtDPaEytN6MAV8CQhA+tw/aSX2BaKTGqR8LtmGSqmWM2qFgOiaYOQKNM8Ee8yhfLkHp8Py4x0g4Am97ALXWNCKnG1CdEzCVfURfmOmGohC6JiDeL7aWG7g414W0YcaKsKOEWQACjugSvJ0jqK4yEN4PodKZE9Ih/wRFkGr4Bu+RdtfsMueQ1U8mIbsYccgO88MqPeUBajFR0P5v6fwezLagTJC991Cp6MXzbQp9zTYM+q+ws9koORnNVIg11THLg+0Yr+M39NZNSeuXBOi2BKS6cfpj1a+QX+OiJU9+A2WLsDWXruLBAAAAAElFTkSuQmCC", "THY": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAABKElEQVR4nJVRPUtDQRCcfT4EFT8SjFFBRLFIioBff8fOJrUillaW/gAxoOhvsNXGKko0kIiIoEHQJBgLJQnx3a3cvrzLpdOplt2Zm9k9YmbGP+BHheiYcTM9B390DCAg+Gxg/aMqMyISnheRv64ucbuUxtpbBcmtLFhpDIxPoLCQQrNUtA4URSospkKnoI3VyjPcHhhYfiqDPC90uI4nw66xHBxxItpnUTvO9SL5sbjpdkUhy2TmTsdGed3d6wmEK0QCk3JuouFPxZDY3LBmIjDXkHGrhZXHB6lfdrbhDQ0jqDZQPzrD/MF+/9IGd5kMuK3Byrg43yNL38vS8g9G0ywXob9/nHjdrMxIX5wLObqGhVaK33OHnE/Mcn5yhmunJ9Jz0RfpL/gFmDugbTpc54oAAAAASUVORK5CYII=", "UAE": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAABNElEQVR4nGVRPUsDQRB9c56FGrBVsLyrRESjGAWjv0JII1hpEWz8FWKhFqKdYCMoSH6Bngi5HDEIwSrpLBQlIMGAhejIzn4RfbDszOzOvJk3dL9QZCKCgBnOBuAtODsAEX6YwRIluScrF/IYHR/qOOD+UN0yMEuCsJjk4TjCZ6sttmZgBJ6TkE8TaWm2dqsLmLgHaQbvAqPLS+jeVSVxIDeC749e31yh9GWcvKps8HJ6BgoH8Xx0gpk0wcPiqrCG/2k1xjfW5c5NT+H92hQiQijKMGOstIa3qwqe9g4c41AcId7fRWuz7CQP1GeFifIWes1HSbbnq9PB6/mll1wlZSKrCgSYr96gm9Xlsb29IxWVco3CihucskJRNmK1t2rNpYnYDTWsgmmJaorhz8DW79uAWeovMH92dUfwQ84AAAAASUVORK5CYII=", "UAL": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAABgElEQVR4nI1SSyhEURj+zrn3ziSM0iDvsiClPJIVlsojNpgZpJRs7M3WjiSlrGm8Zq5kjxQLpSQsLDE23mnGa2bce+6vc0lDirP4T+f85/u/7//+w4iITEH4z1IVBtUQFhw+HQD7E2AEPeAKY7B0HwYbioGHV8SXulGWk/bLc7IjZ4xhdusULXWFEBsDCN8842S6FR3VuVCUZFb2ATAtC6X56bi4e4GUV1bgQuTFwEE4gqo8VxLok0FTOBr9GxgJHEJVuH0dSxi4jMaxP9mMuaG67wyyamaGE3vjTVDbF6B5Qyhwp0KEPNB8OuKGQElmSlLnppDOErqW7f3+MUGsO0RomychLDq7fvrMB8kwLeJSgrAI7TX56JvahStFRWyxC8Md5dB8KyjKSsXE2skXAZfB6QlhrLcSSzvncPToOLt9xsxgLZorsqF5dWweXSW5S0TOzmWq969TLGFSYPvcpnf3r9pSRoPHFH19+5LEfn4NOX555pyBM8CiD3+kbJl7B6Q+vaec42AIAAAAAElFTkSuQmCC", "ASA": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAABcElEQVR4nGNgwAEYmVnYOAX4paLzXXp0zRRd4OLoCs0bpx/hV9W23j1nBYp4XI4zgyXngYcoGtxXHPn//99/ht1zlmO1VUbFgIEFxrHuWXxl34LVDAby0rhcyZBho8zABGLIe4UV8cgoakvw8TKcuf0ALGmvr8rwb+9Uhqer2hgkhPjAYu0rtkD84LHy6P9DyzcyMPz4yfD912+wpKW2IoOEID/D5ftPGa4vqGNgdc0Fi4Nt+P//PwPn//9wxZxsrAzvPn1j0FKQYHj08h1Dw4KtiNADEXZdM/8f3nERLghyytcfPxm4OdjhYhzueQy//vyF2GBpyIXiuV9//jDwehcxyIRVMbQt3QEV+wumwaH05/z61Yr6DqH3L94ACx68cJthQ3M62LOKEsIohsHjYc6ewhepbT/FQWxlKRGGBHdLhtr5mxlkRAUYnrz+ANcAdhIIpLj0S/g7coDZd5+9YXj8+j2YDVPMzMLGwCcsxQAAzPp6oBSf0DMAAAAASUVORK5CYII=", "SWA": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAyElEQVR4nLVROwoCMRCdWUQEQQubxdLac3gAr6Uo6Bn8gKKFJxA8xBYWihZWiqtZcTV5ksCGRGy28MFA5jEv8x7DAEA5EFBOFNxGL9Pr9klMCkSNcsXwzOwNWdC0jyg+4yWlqYOIQeOuOwIjUEqhNB/iKd/mnZVGKiVa64Uv0OTyuDWEHkyEQD0MrUg5H9gMATk+mT3f/J1Bq4uzAdIflnSW9mblW7LNpIfd/Wos6jo9BGjU8UKze7jsGd0uJAFqVmuG8+z9/dIflKz+YVm651wAAAAASUVORK5CYII=", "FFT": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAA8klEQVR4nHVROQoCQRCskUHFZxipIBiYGgtGpl6IT/AINDcw8QeCvzDwB6KRjxERd1tqeg4EbZad2t6anqoa01iNxMCADytg8dgETACgwEVEtEvsvnU/+xL6uXJsbIjguj2gUirjVzXXU8cphNE88h85FFWZ+mIoKi+a8EvyBe+FZd1bgE1/gnGni1/V2syQ5ZnzEyX9IwPAO3tHSZbH0Uxvt0S7WgPDeLyeON8vmpYT7lMyBpbdSrGE03ofJzaWo0QUSX6YkkBw2x2/JOglae7E5IRALHfX5wM/0c2KGboL9dopiRwbmno0kKdklej+J3kfllRmuUeUfuAAAAAASUVORK5CYII=", "NKS": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAABIElEQVR4nGWRvUoDURCFzyxr2CIktiZiY5loKQr2WtqINinE9GksLOIT2PsEWtgLFhERH8BGLC0VSVAs/CmEPTI/dyO4d1m+O+fO3Nkz8no9TxGBLoBQDjQWMXQGkKlKErr0sa+jxxn5pXOeIioG+ImoyBQPzlJllY1Ni8QK6SjaEj1QpgOxX9p5rlrqbD9hePLmiZOrNjdWC650aprB48Esi5pdy/2tOjfXCh7uNW3/frPAXKWjfgPr/bFd8PlN3J21cHr5gYNeEw+PP+guzuDi9svak8mobR6pbcu7L7g/n4vfmNocLiNTHo9ayTifQXhSzSMMiRdZZUZMKFX/517scve3DElFC1gBHVaaiTkkQK5gos1HPY1i0Zrpf+bxC0FflmrrYdiuAAAAAElFTkSuQmCC", "ACA": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAA9ElEQVR4nJVRzUrDQBicXTHUn4Ka0geoCIntyXfQB+i50IsH8dJTDz0KXuzD9CEs9Cx4EN9iE2hSMbsj2eBuJSnSuX0z33zM7AqSxB6QTWR+P0E+emh28BfGUJ32qN/eyaIgvwsyTanOI1Jrt+YMqtN3wubphdn40R/qDv4a9Mcnuc78QhhTXURsgixjpTe3QHCIJIyRdK7LnDauncMYMAbru+FW6QMJSImj52mt4/F8ZjUEgZ2FzZXlgIAlk+4A+NqAAhBBC+3XBWQ/rr+SOumR2rge26iVdsLZJYvlyhNJStW+8odIVpF2wZgq/38/7dW6/AONdwBojII/uAAAAABJRU5ErkJggg==", "WJA": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAA/UlEQVR4nGVSPWqCQRB987HlV1kn4AEE+5zFUtJZBHIGQVHwp7BIICAeQcgR0qTSG+gF0gd25M3O7CfJwu4+5vftmxVZzRQiALgVhrnVTcKjuxseqvRGhBkMml1pBzRnwymK0ml3LnnRE54gpQI7hKE4jZE7g4oo8NC2hlNQsgS5DwTy5LVgct8uzZZKVcF4MET/9IPdx7EGPb6NcD0f0GwX/jYgsd7Tb4vPlwP+LgveMLhTryGVy/7rX/D5+x2ynlf1QrGmcr5bz+sxertNmYxLHliwmCrfYMKEfD6OOrSKnZJS/FCKad5Uc9c9OqXSjhyNacT6ryjc6Y/h3gCBVXRJOKocSQAAAABJRU5ErkJggg==", "HAL": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAA9klEQVR4nGP8/PnzfwYSAAsy5/3Ruwy3azaiKDDbV8DAwMiEqeGUYx9ccCkrI5ytNqscTPOFFTMwCUowMIKchKwYbOr+IjD9YWYpw+tPLAxP37MxGMh/YxBI72ZA2AUFMqk2KPyjt3nAiuFOuhy/AEWBVJQZCj/A+AND51ZZBmERVgaR11sZWNjE+Ri+P3qH4nFBa2Uwu36tFFT0L8O3J38ZOEW/MzCpdwWhmAhTjA1kd4agBisIPJ55mOHfz98Mr7ddwaoJ7GlYqIDA8xWnGV6uv8BgsiMPReHEXYUQT8MEYJqQg1jHQokhtckfRSM4HnA6GgsAAFHHUHuKrcKNAAAAAElFTkSuQmCC", "ELE": "iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAARElEQVR4nGNgIBEw4pMs7Jr2H5nfX5bFyESsYhjAqQEXYCLFdKwa8CkmyUn9ZVngAELRQMh0FA3EKCbJSSgaiDWdLAAABWoU5JOs11QAAAAASUVORK5CYII="}

# Wholly owned US regional subsidiaries use their parent airline's logo.
# Independent regional operators can serve multiple brands and are not aliased.
AIRLINE_PARENT_LOGOS = {
    "ENY": "AAL",  # Envoy Air
    "PDT": "AAL",  # Piedmont Airlines
    "JIA": "AAL",  # PSA Airlines (Blue Streak)
    "EDV": "DAL",  # Endeavor Air
    "QXE": "ASA",  # Horizon Air
}

DIRECTION_TO_SYMBOL_MAPPING = {
    "N": "↑",
    "E": "→",
    "W": "←",
    "S": "↓",
    "NE": "↗",
    "NW": "↖",
    "SE": "↘",
    "SW": "↙",
}

def main(config):
    base_url = config.get("backend_url", "http://backend:5050").rstrip("/")
    location_value = config.get("location")
    if not location_value:
        return render.Root(child = render.Text(content = "Location Missing", font = "tom-thumb"))
    location = json.decode(location_value)
    lat = location["lat"]
    lng = location["lng"]
    radius = int(config.get("radius", "5000"))
    if radius <= 0:
        fail("Search radius must be positive")
    children = []
    nearby = True
    resp = http.get(base_url + "/flights?lat=" + str(lat) + "&lng=" + str(lng) + "&radius=" + str(radius))
    flights = resp.json()["flights"]

    fallback_value = config.get("fallback_location")
    if not flights and fallback_value:
        fallback = json.decode(fallback_value)
        nearby = False
        resp = http.get(base_url + "/flights?lat=" + str(fallback["lat"]) + "&lng=" + str(fallback["lng"]) + "&radius=" + str(int(config.get("fallback_radius", "10000"))) + "&lat4dir=" + str(lat) + "&lng4dir=" + str(lng))
        flights = resp.json()["flights"]

    flight = flights[0] if flights else None
    if flights:
        # Only nearby flights show their direction relative to home.
        primary_text = (DIRECTION_TO_SYMBOL_MAPPING[flight["direction"]] + " " if nearby else "") + flight["callsign"]
        secondary_text = flight["origin_airport_iata"] + " → " + flight["destination_airport_iata"]
        if not flight["on_ground"]:
            tertiary_text = flight["aircraft_code"] + " " + flight["altitude"] + " " + flight["ground_speed"]
        else:
            tertiary_text = flight["aircraft_code"] + " ON GROUND"
    else:
        primary_text = "No"
        secondary_text = "Flights"
        tertiary_text = "Found"

    prefix = flight["callsign"][:3].upper() if flights else "ELE"
    logo_prefix = AIRLINE_PARENT_LOGOS.get(prefix, prefix)
    logo = AIRLINE_LOGOS.get(logo_prefix, AIRLINE_LOGOS["ELE"])
    children.append(render.Row(
        main_align = "center",
        cross_align = "center",
        children = [
            render.Image(src = base64.decode(logo)),
            render.Padding(pad = (2, 0, 0, 0), child = render.Column(
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Text(content = primary_text, font = ("5x8" if len(primary_text) <= 10 else "tom-thumb"), color = "#3979D6"),
                    render.Text(content = secondary_text, font = "5x8", color = "#F2E9D8"),
                ],
            )),
        ],
    ))
    children.append(render.Marquee(
        child = render.Text(content = tertiary_text, font = "tom-thumb", color = "#A2ABB8"),
        width = 64,
        offset_start = 32,
        offset_end = -48,
        align = "center",
    ))

    return render.Root(
        child = render.Box(
            # This Box exists to provide vertical centering
            render.Column(
                expanded = True,
                main_align = "center",  # Controls horizontal alignment
                cross_align = "center",  # Controls vertical alignment
                children = children,
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(id = "location", name = "Overhead location", desc = "Search here first for flights overhead", icon = "locationDot"),
            schema.Text(id = "radius", name = "Search radius (meters)", desc = "Positive distance in meters", default = "5000", icon = "circle"),
            schema.Location(id = "fallback_location", name = "Fallback location", desc = "Search here only when there are no flights overhead", icon = "plane"),
            schema.Text(id = "fallback_radius", name = "Fallback radius (meters)", desc = "Positive distance in meters", default = "10000", icon = "circle"),
            schema.Text(id = "backend_url", name = "Flight service URL", desc = "URL of your self-hosted compatible flight service, reachable by Tronbyt Server", default = "http://backend:5050", icon = "link"),
        ],
    )
