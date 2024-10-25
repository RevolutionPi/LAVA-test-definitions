# Configurations RevPi devices

| Name          | Setup                                                                                 |
| ---           | ---                                                                                   |
| config000.rsc | RevPi                                                                                 |
| config001.rsc | DIO <- RevPi                                                                          |
| config002.rsc | MIO <- RevPi                                                                          |
| config003.rsc | MIO <- DIO <- RevPi                                                                   |
| config004.rsc | GW Serial RX <- DO <- DI <- RevPi -> DI -> DO -> GW Profinet IRT                      |
| config005.rsc | DIO <- DO <- RevPi -> AIO -> MIO                                                      |
| config006.rsc | DIO <- MIO <- AIO <- RevPi -> AIO -> MIO -> DIO                                       |
| config007.rsc | DIO <- RevPi -> DIO                                                                   |
| config008.rsc | MIO <- RevPi -> MIO                                                                   |
| config009.rsc | MIO <- DIO <- RevPi -> DIO -> MIO                                                     |
| config010.rsc | GW Profinet IRT <- DIO <- MIO <- AIO <- RevPi                                         |
| config011.rsc | GW Profinet IRT <- DIO <- MIO <- AIO <- RevPi -> AIO -> MIO -> DIO -> GW Modbus TCP   |
| config012.rsc | DO <- DI <- RevPi -> DI -> DO                                                         |
| config013.rsc | DIO <- MIO <- AIO <- RevPi                                                            |
| config014.rsc | DIO <- RO <- RevPi -> GW Modbus TCP                                                   |
| config015.rsc | DIO <- RevPi -> RO -> GW Modbus TCP                                                   |
| config016.rsc | GW Ethernet IP <- DIO <- MIO <- AIO <- RevPi -> AIO -> MIO -> DIO -> GW Modbus TCP    |
