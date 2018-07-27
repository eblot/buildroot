################################################################################
#
# python-ruamel-yaml
#
################################################################################

PYTHON_RUAMEL_YAML_VERSION = 0.15.45
PYTHON_RUAMEL_YAML_SOURCE = ruamel.yaml-$(PYTHON_RUAMEL_YAML_VERSION).tar.gz
PYTHON_RUAMEL_YAML_SITE = https://pypi.python.org/packages/63/a5/dba37230d6cf51f4cc19a486faf0f06871d9e87d25df0171b3225d20fc68
PYTHON_RUAMEL_YAML_SETUP_TYPE = distutils
PYTHON_RUAMEL_YAML_LICENSE = MIT
PYTHON_RUAMEL_YAML_LICENSE_FILES = LICENSE

$(eval $(python-package))
