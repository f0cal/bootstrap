# -*- coding: utf-8 -*-
from pkg_resources import get_distribution, DistributionNotFound, resource_filename

try:
    # Change here if project is renamed and does not equal the package name
    dist_name = 'f0cal.bootstrap'
    __version__ = get_distribution(dist_name).version
except DistributionNotFound:
    __version__ = 'unknown'
finally:
    del get_distribution, DistributionNotFound

def saltbox_path():
    return resource_filename(__name__, 'saltbox')
