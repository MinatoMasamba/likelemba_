from django import template

register = template.Library()

# Taux fixe FC/USD utilisé uniquement pour l'affichage indicatif (même
# convention que le prototype de design) — aucune conversion réelle n'a
# lieu, les montants restent stockés et traités en FC partout ailleurs.
FC_PER_USD = 2800


@register.filter
def usd(value):
    try:
        amount = float(value)
    except (TypeError, ValueError):
        return ""
    return f"${amount / FC_PER_USD:,.2f}"


@register.filter
def fc(value):
    """Montant FC formaté avec espace comme séparateur de milliers (convention française)."""
    try:
        amount = round(float(value))
    except (TypeError, ValueError):
        return ""
    return f"{amount:,}".replace(",", " ")
