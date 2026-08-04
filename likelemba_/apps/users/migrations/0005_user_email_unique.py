from django.db import migrations, models


def blank_email_to_null(apps, schema_editor):
    """Les emails vides ('') doivent devenir NULL avant d'ajouter la contrainte
    unique : sinon plusieurs comptes avec '' violeraient la contrainte."""
    User = apps.get_model('users', 'User')
    User.objects.filter(email='').update(email=None)


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0004_remove_userprofile_account_type_user_account_type'),
    ]

    operations = [
        migrations.RunPython(blank_email_to_null, migrations.RunPython.noop),
        migrations.AlterField(
            model_name='user',
            name='email',
            field=models.EmailField(
                blank=True,
                help_text="Adresse email (utilisée pour la connexion au tableau de bord)",
                max_length=254,
                null=True,
                unique=True,
            ),
        ),
    ]
