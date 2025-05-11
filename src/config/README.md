# config

- Immutable when in memory
- Lazily loaded singleton
- config struct is a DTO that supports access like config().attribute.attribute nested at indefinite length
- only public interface is config() which returns the in memory singleton
- configuration on disk is in yaml
- reverse merge from /etc/${app}/config.yml ~/.config/${app}/config.yml .${app}.yml and ${app}.yml
