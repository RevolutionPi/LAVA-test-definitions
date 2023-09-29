# Configurations RevPi_Core

| Name          | Setup                                                                                     |
| ---           | ---                                                                                       |
| config001.rsc | DIO <- Core -> DIO                                                                        |
| config002.rsc | MIO <- Core -> MIO                                                                        |
| config003.rsc | MIO <- DIO <- Core -> DIO -> MIO                                                          |
| config004.rsc | GW Serial RX <- DO <- DI <- Core -> DI -> DO -> GW Profinet IRT                           |
| config006.rsc | GW Profinet IRT <- DIO <- MIO <- AIO <- Connect 4 -> AIO -> MIO -> DIO -> GW Modbus TCP   |