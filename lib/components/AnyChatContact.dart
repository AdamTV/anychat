import 'package:contacts_service/contacts_service.dart';

class AnyChatContact extends Contact {
  final bool isRegistered;
  final String anyChatId;

  AnyChatContact(Contact c, this.isRegistered, this.anyChatId)
      : super(
            displayName: c.displayName,
            givenName: c.givenName,
            middleName: c.middleName,
            prefix: c.prefix,
            suffix: c.suffix,
            familyName: c.familyName,
            company: c.company,
            jobTitle: c.jobTitle,
            emails: c.emails,
            phones: c.phones,
            postalAddresses: c.postalAddresses,
            avatar: c.avatar,
            birthday: c.birthday,
            androidAccountType: c.androidAccountType,
            androidAccountTypeRaw: c.androidAccountTypeRaw,
            androidAccountName: c.androidAccountName
  );
}
