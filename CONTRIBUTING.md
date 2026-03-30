# Contribuindo

Contribuições são bem-vindas! Siga as diretrizes abaixo.

## Como contribuir

1. Fork o repositório
2. Crie uma branch (`git checkout -b minha-feature`)
3. Faça suas mudanças
4. Teste o script manualmente em Ubuntu ou Kali
5. Garanta que passa no ShellCheck: `shellcheck scripts/seu-script.sh`
6. Commit (`git commit -m "add: descrição curta"`)
7. Push (`git push origin minha-feature`)
8. Abra um Pull Request

## Padrão de scripts

Todos os scripts devem seguir este padrão:

```bash
#!/usr/bin/env bash
# ─────────────────────────────────────────
# nome-do-script.sh
# Descrição curta do que faz
# ─────────────────────────────────────────

set -e

echo "nome — descrição curta..."

# verificar se já está instalado antes de instalar
# fazer backup antes de sobrescrever configs
# usar command -v ao invés de which
# funcionar standalone (sem dependência de outros scripts)
```

### Regras

- Cada script deve funcionar **independente** — `bash <(curl -fsSL URL)` direto
- Usar `set -e` no início
- Verificar se ferramentas já estão instaladas antes de reinstalar
- Fazer backup antes de sobrescrever qualquer config
- Suportar Ubuntu 22.04+, 24.04+ e Kali Linux
- Sem comentários óbvios no código
- Português nas mensagens pro usuário, inglês no código

### Checklist do PR

- [ ] Script funciona standalone via curl
- [ ] Passa no `shellcheck` sem erros
- [ ] Passa no `bash -n` (syntax check)
- [ ] Testado em Ubuntu ou Kali
- [ ] Faz backup antes de sobrescrever configs
- [ ] Verifica se ferramentas já existem antes de instalar
- [ ] README atualizado (se adicionou script novo)

## Issues

- Use o template de **Bug Report** para reportar problemas
- Use o template de **Feature Request** para sugerir novos scripts
- Descreva a distro e versão onde testou

## Dúvidas

Abra uma issue com a tag `question`.
