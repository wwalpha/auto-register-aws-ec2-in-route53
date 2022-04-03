import { EC2, Route53 } from 'aws-sdk';

const client = new EC2({
  region: process.env.DEFAULT_REGION,
});
const dnsClient = new Route53({
  region: process.env.DEFAULT_REGION,
});

interface RuleEvent {
  instance: string;
  instanceAlias: string;
  state: string;
  zoneName: string;
}

export const handler = async (e: RuleEvent) => {
  console.log(e);

  if (e.state !== 'running') {
    return;
  }

  const result = await client
    .describeInstances({
      InstanceIds: [e.instance],
    })
    .promise();

  const instance = result.Reservations?.[0].Instances?.[0];
  const publicIp = instance?.PublicIpAddress;

  if (!publicIp) return;

  const zones = await dnsClient
    .listHostedZonesByName({
      DNSName: e.zoneName,
    })
    .promise();

  // validate
  if (zones.HostedZones.length === 0) return;

  // update record
  await dnsClient
    .changeResourceRecordSets({
      HostedZoneId: zones.HostedZones[0].Id,
      ChangeBatch: {
        Changes: [
          {
            Action: 'UPSERT',
            ResourceRecordSet: {
              Name: e.instanceAlias,
              Type: 'A',
              TTL: 60,
              ResourceRecords: [
                {
                  Value: publicIp,
                },
              ],
            },
          },
        ],
      },
    })
    .promise();
};
