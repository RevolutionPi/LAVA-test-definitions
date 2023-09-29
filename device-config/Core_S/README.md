# Configurations

| Name          | Setup                               |
| ---           | ---                                 |
| config001.rsc | DIO <- Core S -> DIO               |
| config002.rsc | MIO <- Core S -> MIO               |
| config003.rsc | MIO <- DIO <- Core S -> DIO -> MIO |
| config006.rsc | GW Profinet IRT <- DIO <- MIO <- AIO <- Connect 4 -> AIO -> MIO -> DIO -> GW Modbus TCP   |