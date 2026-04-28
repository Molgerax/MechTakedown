using System.Collections.Generic;
using UnityEngine;

namespace MechTech.Runtime.Gameplay.Ropes
{
    public class Rope : MonoBehaviour
    {
        [SerializeField] private Transform target;
        [SerializeField] private float targetLength = 5f;
        [SerializeField] private float forceStrength = 1f;

        [SerializeField] private int nodeCount = 20;
        
        public List<RopeNode> Nodes = new();

        public RopePoint[] Points;
        
        private float _totalLength;

        private void Start()
        {
            var node = new RopeNode(transform.position, transform.right, transform);
            Nodes.Add(node);
            var newNode = new RopeNode(target.position, target.right, target);
            Nodes.Add(newNode);

            Points = new RopePoint[nodeCount];

            for (int i = 0; i < nodeCount; i++)
            {
                float t = (float) i / (nodeCount - 1f);

                Points[i] = new (Vector3.Lerp(Nodes[0].Position, Nodes[1].Position, t));
            }
        }

        private void FixedUpdate()
        {
            for (int i = 0; i < 8; i++)
            {
                DetectCollisionsBetween();
                //MoveNodes();
                RemoveRedundantNodes();
                CalculateLength();
                ApplyForces();   
            }
        }

        private void DetectCollisionsBetween()
        {
            for (int i = Nodes.Count - 2; i >= 0; i--)
            {
                RopeNode node = Nodes[i];
                RopeNode nextNode = Nodes[i + 1];

                if (Physics.Linecast(nextNode.Position, node.Position, out var hitInfo))
                {
                    Vector3 normal = (hitInfo.normal).normalized;
                    Vector3 pos = (hitInfo.point);
                    var newNode = new RopeNode(pos + normal * 0.1f, normal, hitInfo.transform);
                    Nodes.Insert(i + 1, newNode);

                }
            }
            
            for (int i = 0; i > Nodes.Count - 1; i--)
            {
                RopeNode node = Nodes[i];
                RopeNode nextNode = Nodes[i + 1];

                if (Physics.Linecast(node.Position, nextNode.Position, out var hitInfo))
                {
                    Vector3 normal = (hitInfo.normal).normalized;
                    Vector3 pos = (hitInfo.point);
                    var newNode = new RopeNode(pos + normal * 0.1f, normal, hitInfo.transform);
                    Nodes.Insert(i, newNode);

                }
            }
        }
        
        
        private void RemoveRedundantNodes()
        {
            for (int i = Nodes.Count - 3; i >= 0; i--)
            {
                RopeNode node = Nodes[i];
                RopeNode nextNode = Nodes[i + 2];

                RopeNode middle = Nodes[i + 1];
                
                //if (Vector3.Dot(nextNode.Position - middle.Position, middle.Normal) < 0)
                //    continue;

                Vector3 middlePoint = (node.Position + nextNode.Position) / 2f;

                Vector3 v = middlePoint - middle.Position;
                
                if (!Physics.Linecast(nextNode.Position, node.Position))
                {
                    if (Physics.Linecast(middle.Position, middlePoint, out var hitInfo))
                    {
                        //middle.Reset(hitInfo.point - v.normalized * 0.1f, hitInfo.normal, hitInfo.transform);    
                    }
                    else 
                        Nodes.RemoveAt(i + 1);
                }
            }
        }
        
        
        
        private void MoveNodes()
        {
            if (_totalLength < targetLength)
                return;
            
            for (int i = Nodes.Count - 3; i >= 0; i--)
            {
                RopeNode node = Nodes[i];
                RopeNode nextNode = Nodes[i + 2];

                RopeNode middle = Nodes[i + 1];
                
                Vector3 middlePoint = (node.Position + nextNode.Position) / 2f;

                if (Vector3.Dot(middlePoint - middle.Position, middle.Normal) > 0)
                {
                    middle.Detach();
                    middle.Position = Vector3.MoveTowards(middle.Position, middlePoint, 1f * Time.fixedDeltaTime);
                }                    
            }
        }


        private void CalculateLength()
        {
            _totalLength = 0;
            for (int i = Nodes.Count - 2; i >= 0; i--)
            {
                RopeNode node = Nodes[i];
                RopeNode nextNode = Nodes[i + 1];

                _totalLength += Vector3.Distance(node.Position, nextNode.Position);
            }
        }

        private void ApplyForces()
        {
            if (_totalLength < targetLength)
                return;

            float summedForce = 0;
            float totalForce = (_totalLength - targetLength) * forceStrength;
            
            for (int i = Nodes.Count - 3; i >= 0; i--)
            {
                RopeNode middle = Nodes[i + 1];
                
                if (!middle.Rigidbody)
                    continue;
                
                RopeNode node = Nodes[i];
                RopeNode nextNode = Nodes[i + 2];

                Vector3 middlePoint = (node.Position + nextNode.Position) / 2f;

                Vector3 normal = middlePoint - middle.Position;

                summedForce += normal.magnitude;
            }
            
            for (int i = Nodes.Count - 3; i >= 0; i--)
            {
                RopeNode middle = Nodes[i + 1];
                
                if (!middle.Rigidbody)
                    continue;
                
                RopeNode node = Nodes[i];
                RopeNode nextNode = Nodes[i + 2];

                Vector3 middlePoint = (node.Position + nextNode.Position) / 2f;

                Vector3 normal = middlePoint - middle.Position;

                float strength = normal.magnitude / summedForce * totalForce;

                middle.Rigidbody.AddForceAtPosition(normal.normalized * strength, middle.Position, ForceMode.Force);
            }
        }

        public struct RopePoint
        {
            public Vector3 Position;
            public Vector3 OldPosition;

            public RopePoint(Vector3 position)
            {
                Position = position;
                OldPosition = position;
            }
        }
        
        public class RopeNode
        {
            public Vector3 Position
            {
                get => AttachedTransform ? AttachedTransform.TransformPoint(LocalPosition) : _position;
                set => _position = value;
            }

            private Vector3 _position;
            public Transform AttachedTransform;
            public Rigidbody Rigidbody;
            public Vector3 LocalPosition;
            public Vector3 Normal => AttachedTransform ? AttachedTransform.TransformDirection(_localNormal) : _normal;
            private Vector3 _localNormal;
            private Vector3 _normal;

            public RopeNode(Vector3 position)
            {
                _position = position;
                LocalPosition = position;
                AttachedTransform = null;
            }

            public RopeNode(Vector3 position, Vector3 normal, Transform transform)
            {
                _position = position;
                AttachedTransform = transform;
                LocalPosition = transform.InverseTransformPoint(position);
                _normal = normal;
                _localNormal = transform.InverseTransformDirection(normal);

                transform.TryGetComponent(out Rigidbody);
            }

            public void Reset(Vector3 position, Vector3 normal, Transform transform)
            {
                _position = position;
                AttachedTransform = transform;
                LocalPosition = transform.InverseTransformPoint(position);
                _normal = normal;
                _localNormal = transform.InverseTransformDirection(normal);

                transform.TryGetComponent(out Rigidbody);
            }

            public void Detach()
            {
                AttachedTransform = null;
                Rigidbody = null;
            }
        }


        private void OnDrawGizmos()
        {
            Gizmos.color = (_totalLength < targetLength) ? Color.red : Color.green;
            
            RopeNode previous = null;
            foreach (RopeNode node in Nodes)
            {
                if (previous != null && node != null)
                {
                    Gizmos.DrawLine(previous.Position, node.Position);
                }
                if (node != null)
                    Gizmos.DrawSphere(node.Position, 0.1f);

                previous = node;
            }
        }
    }
}
