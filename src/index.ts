import { DynamoDB, EC2, Route53 } from 'aws-sdk';

const client = new EC2({
  region: process.env.DEFAULT_REGION,
});
const dnsClient = new Route53({
  region: process.env.DEFAULT_REGION,
});
const dbClient = new DynamoDB.DocumentClient({
  region: process.env.DEFAULT_REGION,
});

const ZONE_NAME = process.env['ZONE_NAME'] as string;
const TABLE_NAME = process.env['TABLE_NAME'] as string;

interface RuleEvent {
  instance: string;
  state: string;
}

export const handler = async (e: RuleEvent) => {
  if (e.state !== 'running') {
    return;
  }

  try {
    // check public IP
    const publicIP = await getPublicIP(e.instance);

    // search database
    const alias = await getAlias(e.instance);

    // register domain
    await register(alias, publicIP);
  } catch (e) {
    console.log(e);
  }
};

const getPublicIP = async (instanceId: string) => {
  const result = await client
    .describeInstances({
      InstanceIds: [instanceId],
    })
    .promise();

  const instance = result.Reservations?.[0].Instances?.[0];

  if (!instance?.PublicIpAddress) {
    throw new Error('Public IP not found.');
  }

  return instance?.PublicIpAddress;
};

const getAlias = async (instanceId: string) => {
  const result = await dbClient
    .get({
      TableName: TABLE_NAME,
      Key: {
        Id: instanceId,
      },
    })
    .promise();

  const item = result.Item;

  if (!item) {
    throw new Error('Not Registered');
  }

  return (result.Item as Records).Alias;
};

const register = async (alias: string, ipAddress: string) => {
  const zones = await dnsClient
    .listHostedZonesByName({
      DNSName: ZONE_NAME,
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
              Name: alias,
              Type: 'A',
              TTL: 60,
              ResourceRecords: [
                {
                  Value: ipAddress,
                },
              ],
            },
          },
        ],
      },
    })
    .promise();
};

interface Records {
  Id: string;
  IpAddress: string;
  Alias: string;
  ExpireDate: string;
}
