import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/stores/views/home.dart';

import '../../../../../utils/validation_helper.dart';

class ConnectTargetInput extends StatelessWidget {
  final TextEditingController host;
  final bool manual;

  const ConnectTargetInput({
    Key? key,
    required this.host,
    required this.manual,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    HomeStore landingStore = GetIt.instance<HomeStore>();

    return Observer(builder: (_) {
      return Column(
        children: [
          TextFormField(
            controller: this.host,
            autocorrect: false,
            readOnly: !this.manual,
            enabled: this.manual,
            onChanged: (host) =>
                this.manual ? landingStore.typedInConnection.host = host : null,
            decoration: InputDecoration(
              labelText: !landingStore.domainMode
                  ? 'IP Address (internal)'
                  : 'Hostname',
              hintText: !landingStore.domainMode
                  ? 'e.g. 192.168.178.10'
                  : 'e.g. wss://obs-stream.com',
            ),
            validator: (text) => !landingStore.domainMode
                ? ValidationHelper.ipValidation(text)
                : null,
          ),
          // const SizedBox(height: 6.0),
          this.manual
              ? SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: CupertinoSlidingSegmentedControl<bool>(
                      groupValue: landingStore.domainMode,
                      children: const {
                        false: Text('IP'),
                        true: Text('Domain'),
                      },
                      onValueChanged: (domainMode) {
                        this.host.clear();
                        Form.of(context)?.reset();
                        FocusManager.instance.primaryFocus?.unfocus();
                        landingStore.setDomainMode(domainMode ?? true);
                      },
                    ),
                  ),
                )
              : Container(),
        ],
      );
    });
  }
}
