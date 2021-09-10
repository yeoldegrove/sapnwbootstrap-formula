{%- from "netweaver/map.jinja" import netweaver with context -%}
{% set host = grains['host'] %}

prometheus_sap_host_exporter_pkg:
  pkg.installed:
    - name: prometheus-sap_host_exporter

# the sid, instance number pair of a node is unique, so we need to adapt configuration
{% for node in netweaver.nodes %}

# test if running on HA ASCS+ERS
{% if netweaver.ha_enabled and node.sap_instance in ["ascs", "ers"] %}
{% set on_ha_cs = True %}
# do not enable ASCS and ERS exporter service in HA use case (handled by pacemaker)
{% set service_status = "disabled" %}
{% set service_enabled = False %}
{% else %}
{% set on_ha_cs = False %}
{% set service_status = "running" %}
{% set service_enabled = True %}
{% endif %}

# in non-HA use case create ASCS|ERS|PAS|AAS configuration
# in HA use case create additional ASCS|ERS configuration on ERS|ASCS
{% if (host == node.host or on_ha_cs) and node.sap_instance != "db" %}

{% set sap_instance_nr = '{:0>2}'.format(node.instance) %}
{% set exporter_instance = '{}_{}{}'.format(node.sid.upper(), node.sap_instance.upper(), sap_instance_nr) %}
{% set instance_name = node.sid.upper()~'_'~sap_instance_nr %}
{% set monitoring_hosts = node.monitoring_hosts|default([node.virtual_host]) %}

{% for monitoring_host in monitoring_hosts %}
# be backward compatible with cluster resource names
{% if monitoring_host == node.virtual_host %}
{% set append_name = "" %}
{% else %}
{% set append_name = "_" + monitoring_host %}
{% endif %}
# we bind each exporter instance to a SAP instance virtual host or the values passed to "monitoring_hosts"
sap_host_exporter_configuration_{{ exporter_instance }}_{{ monitoring_host }}:
  file.managed:
    - name: /etc/sap_host_exporter/{{ exporter_instance }}{{ append_name }}.yaml
    - contents: |
         address: {{ monitoring_host }}
         sap-control-uds: /tmp/.sapstream5{{ sap_instance_nr }}13
    - require:
      - pkg: prometheus_sap_host_exporter_pkg
# on HA use case deploy ASCS|ERS on ERS|ASCS
{% if on_ha_cs %}
    - onlyif:
      - test -d /usr/sap/{{ node.sid.upper() }}/ASCS* || test -d /usr/sap/{{ node.sid.upper() }}/ERS*
{% endif %}

sap_host_exporter_service_{{ exporter_instance }}_{{ monitoring_host }}:
  service.{{ service_status }}:
    # be backward compatible with cluster resource names
    - name: prometheus-sap_host_exporter@{{ exporter_instance }}{{ append_name }}
    - enable: {{ service_enabled }}
    - restart: True
    - require:
      - pkg: prometheus_sap_host_exporter_pkg
      - file: sap_host_exporter_configuration_{{ exporter_instance }}_{{ monitoring_host }}
# on HA use case deploy ASCS|ERS on ERS|ASCS
{% if on_ha_cs %}
    - onlyif:
      - test -d /usr/sap/{{ node.sid.upper() }}/ASCS* || test -d /usr/sap/{{ node.sid.upper() }}/ERS*
# on non-HA use case watch file for changes (not possible for disabled service)
{% else %}
    - watch:
      - file: sap_host_exporter_configuration_{{ exporter_instance }}_{{ monitoring_host }}
{% endif %}

{% endfor %}
{% endif %}
{% endfor %}
