lxc:
  pkg.installed: []

/var/lib/lxc/autodev.sh:
  file.managed:
    - source: salt://lxc-containers/autodev.sh
      mode: 0755

{%- set n = 0 %}
{%- for id, container in pillar['containers'].items() %}

/var/lib/lxc/{{ id }}:
  cmd.run:
    - name: lxc-create -n {{ id }} -B dir -t debian -- -r stretch --packages=salt-minion
    - require:
        - pkg: lxc
    - creates: /var/lib/lxc/{{ id }}

/var/lib/lxc/{{ id }}/config:
  file.managed:
    - source: salt://lxc-containers/config
    - template: 'jinja'
    - context:
        id: {{ id }}
        container: {{ container }}
        hwaddr_prefix: '0A:14:48:01:{{ n.__str__().rjust(2, '0') }}'
    - require:
        - cmd: /var/lib/lxc/{{ id }}

/var/lib/lxc/{{ id }}/rootfs/etc/hosts:
  file.managed:
    - source: salt://lxc-containers/hosts
    - template: 'jinja'
    - context:
        id: {{ id }}
        container: {{ container }}
    - require:
        - cmd: /var/lib/lxc/{{ id }}

autostart-{{ id }}:
  service.enabled:
      - name: lxc@{{ id }}
        require_in:
          file: /var/lib/lxc/{{ id }}/config

start-{{ id }}:
  service.running:
      - name: lxc@{{ id }}
        require:
          - service: autostart-{{ id }}

{%- set n = n + 1 %}
{% endfor %}
