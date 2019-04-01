// すべてPOSTリクエストでコールする
const WEBAUTHN_API = {
  // ユーザー登録
  ATTESTATION: {
    // navigator.credentials.create 用のチャレンジ・オプション生成
    OPTIONS: '/attestation/options',
    // navigator.credentials.create の呼び出しの送信先
    RESULT: '/attestation/result',
  },
  // ログイン処理
  ASSERTION: {
    // navigator.credentials.get 用のチャレンジ・オプション生成
    OPTIONS: '/assertion/options',
    // navigator.credentials.get の呼び出し結果の送信先
    RESULT: '/assertion/result',
  }
};

export default ({ app }, inject) => {
  const attestation = async (username) => {
    // WebAuthn API用の呼び出し用のオプションの生成、チャレンジ生成
    const credentialOptions = await app.$axios.$post(
      WEBAUTHN_API.ATTESTATION.OPTIONS, {
      username: username,
      displayName: username,
      attestation: 'none'
    });

    if (credentialOptions) {
      // バイナリ変換
      credentialOptions["challenge"] = encoder.strToBin(credentialOptions["challenge"]);
      credentialOptions["user"]["id"] = encoder.strToBin(credentialOptions["user"]["id"]);

      // WebAuthentication APIの呼び出し
      const attestation = await navigator.credentials.create({"publicKey": credentialOptions});

      // API呼び出し結果をサーバーサイドへ送信
      const requestBody = {
        id: attestation.id,
        rawId: attestation.id,
        response: {
          clientDataJSON: encoder.binToStr(attestation.response.clientDataJSON),
          attestationObject: encoder.binToStr(attestation.response.attestationObject)
        },
        type: 'public-key'
      };
      const registResponse = await app.$axios.$post(WEBAUTHN_API.ATTESTATION.RESULT, requestBody);
      if (registResponse) {
        console.log(`${username} registration succeeded.`);
      }
    }
  };

  const assertion = async (username) => {
    const credentialOptions = await app.$axios.$post(WEBAUTHN_API.ASSERTION.OPTIONS, {
      username: username,
      userVerification: 'required'
    });

    if (credentialOptions) {
      credentialOptions["challenge"] = encoder.strToBin(credentialOptions["challenge"]);
      credentialOptions["allowCredentials"].forEach(function (cred) {
        cred["id"] = encoder.strToBin(cred["id"]);
      });

      const assertion = await navigator.credentials.get({"publicKey": credentialOptions});
      const requestBody = {
        id: encoder.binToStr(assertion.rawId),
        rawId: encoder.binToStr(assertion.rawId),
        response: {
          clientDataJSON: encoder.binToStr(assertion.response.clientDataJSON),
          signature: encoder.binToStr(assertion.response.signature),
          userHandle: encoder.binToStr(assertion.response.userHandle),
          authenticatorData: encoder.binToStr(assertion.response.authenticatorData)
        }
      };

      const sessionCreateResponse = await app.$axios.post(WEBAUTHN_API.ASSERTION.RESULT, requestBody);
      if (sessionCreateResponse) {
        console.log(`${username} login succeeded.`);
      }
    }
  };

  const encoder = {
    binToStr: (bin) => btoa(new Uint8Array(bin).reduce((s, byte) => s + String.fromCharCode(byte), '')),
    strToBin: (str) => Uint8Array.from(atob(str), c => c.charCodeAt(0))
  };

  inject('webauthn', {
    attestation,
    assertion,
    encoder
  });
};
