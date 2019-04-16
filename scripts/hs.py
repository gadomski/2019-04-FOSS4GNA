def hs(ins, outs):
    gps_time = ins['GpsTime']
    z = ins['Z']
    hs = z - gps_time
    outs['GpsTime'] = hs
    return True
